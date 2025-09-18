import argv
import gleam/erlang/process.{type Subject, receive}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/pair
import gleam/result
import gleam/time/duration
import gleam/time/timestamp

pub fn main() -> Nil {
  let time_start = timestamp.system_time()
  let assert Ok(args) = list.rest(argv.load().arguments)
  let len = list.length(args)
  case len {
    3 -> {
      //get num of nodes
      let assert Ok(num_string) = list.first(args)
      let assert Ok(n) = int.parse(num_string)
      //throw away num nodes and get topology
      let assert Ok(args) = list.rest(args)
      let assert Ok(topology) = list.first(args)
      //throw away topology and get alogorithm
      let assert Ok(args) = list.rest(args)
      let assert Ok(algorithm) = list.first(args)
      let assert Ok(monitor) =
        actor.new(n) |> actor.on_message(monitor_handler) |> actor.start
      let empty_actors = []
      let actors =
        start_workers(n, topology, algorithm, empty_actors, monitor.data)
      let random_actor = find_random_actor(actors, list.length(actors))
      case algorithm {
        "gossip" -> {
          actor.send(random_actor, Gossip(8.0))
          monitor_loop(monitor.data, 0, n)
          Nil
        }
        "push-sum" -> {
          actor.send(random_actor, Start)
          monitor_loop(monitor.data, 0, n)
          Nil
        }
        _ -> {
          io.println("Invalid algorithm")
        }
      }
    }
    _ -> Nil
  }
  let time_end = timestamp.system_time()
  let duration = timestamp.difference(time_start, time_end)
  let time = duration.to_seconds(duration)
  io.println(float.to_string(time))
}

///tracker
pub type Monitor {
  Update
}

fn monitor_handler(state: Int, message: Monitor) -> actor.Next(Int, Monitor) {
  case message {
    //when update is called an actor has achieved convergence
    Update -> {
      case state > 0 {
        True -> {
          let new_state = state - 1
          actor.continue(new_state)
        }
        False -> {
          actor.stop()
        }
      }
    }
  }
}

fn monitor_loop(subject: Subject(Monitor), count: Int, total: Int) {
  case receive(subject, 500) {
    Ok(Update) -> {
      let new_count = count - 1
      case new_count == total {
        True -> {
          io.println("All actors reached convergence.")
          actor.stop()
        }
        False -> {
          monitor_loop(subject, new_count, total)
        }
      }
    }
    Error(_) -> {
      monitor_loop(subject, count, total)
    }
  }
}

///worker message def
pub type Message {
  PushSum(sum: Float, weight: Float)
  Gossip(Float)
  NeighborSetUp(List(#(Int, Subject(Message))))
  Start
}

pub type State {
  State(
    val1: Float,
    //rumor for gossip, sum for push-sum
    val2: Float,
    //num times heard for gossip, weight for push-sum
    val3: Int,
    //stays 0 for gossip, num times unchanged for push-sum
    neighbors: List(#(Int, Subject(Message))),
    //neighbors, assigned based on topology
    monitor: Subject(Monitor),
  )
}

///define the start fucntion for when a worker is messaaged
/// when a work receives the start meesage it starts calculations
fn worker_handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    PushSum(sum, weight) -> {
      //do push sum alg:
      //update new sum/weight
      let curr_sum = state.val1 +. sum
      let halved_sum = curr_sum /. 2.0
      let curr_weight = state.val2 +. weight
      let halved_weight = curr_weight /. 2.0
      //pick random neighbor to pass half to
      let subject = rand_neighbor(state.neighbors)
      //send half of new sum and weight to neighbor
      actor.send(subject, PushSum(halved_sum, halved_weight))

      //calculate ratio to check convergence
      let prev_ratio = state.val1 /. state.val2
      let curr_ratio = halved_sum /. halved_weight
      //if no change, update count
      let num_repeats = case
        float.absolute_value(prev_ratio -. curr_ratio) <=. 1.0e-10
      {
        True -> state.val3 + 1
        False -> 0
      }

      case num_repeats == 3 {
        True -> {
          actor.send(state.monitor, Update)
          actor.stop()
        }
        False -> {
          //set new state and continue
          let new_state =
            State(
              halved_sum,
              halved_weight,
              num_repeats,
              state.neighbors,
              state.monitor,
            )
          actor.continue(new_state)
        }
      }
    }
    Gossip(rumor) -> {
      //if you still have more time to hear the rumor
      case state.val2 >. 0.0 {
        True -> {
          case state.val1 == 0.0 {
            True -> {
              //actor has reached convergence
              actor.send(state.monitor, Update)
            }
            False -> {
              Nil
            }
          }
          let new_count = float.subtract(state.val2, 1.0)
          let neighbor = rand_neighbor(state.neighbors)
          actor.send(neighbor, Gossip(rumor))
          let new_state =
            State(rumor, new_count, 0, state.neighbors, state.monitor)
          actor.continue(new_state)
        }
        False -> {
          io.println("I will no longer hear the rumor")
          actor.stop()
        }
      }
      actor.stop()
    }
    NeighborSetUp(neighbors) -> {
      //receive list of neighbors
      let new_state = State(state.val1, state.val2, 0, neighbors, state.monitor)
      actor.continue(new_state)
    }
    Start -> {
      //only needed for push algorithm
      //set values to half
      let halved_sum = state.val1 /. 2.0
      let halved_weight = state.val2 /. 2.0
      //pick random neighbor to send values to
      let subject =
        find_random_actor(state.neighbors, list.length(state.neighbors))
      actor.send(subject, PushSum(halved_sum, halved_weight))
      //set up new state with half values
      let new_state =
        State(halved_sum, halved_weight, 0, state.neighbors, state.monitor)
      actor.continue(new_state)
    }
  }
}

pub fn build_state(n: Int, algorithm: String, monitor: Subject(Monitor)) {
  case algorithm {
    "gossip" -> {
      State(0.0, 10.0, 0, [], monitor)
      //val1 represents rumor, val2 = num times node has received rumor
    }
    "push-sum" -> {
      let n_float = int.to_float(n)

      State(n_float, 1.0, 0, [], monitor)
      //val1 = sum, val2 = weight
    }
    _ -> {
      io.println("invalid algorithm input")
      State(0.0, 0.0, 0, [], monitor)
    }
  }
}

pub fn start_workers(
  n: Int,
  topology: String,
  algorithm: String,
  workers: List(#(Int, Subject(Message))),
  monitor: Subject(Monitor),
) -> List(#(Int, Subject(Message))) {
  case n > 0 {
    True -> {
      //initial state will depend on the algorithm
      let initial_state = build_state(n, algorithm, monitor)

      let assert Ok(actor) =
        //set up actor
        actor.new(initial_state)
        |> actor.on_message(worker_handle_message)
        |> actor.start

      //add new actor to list
      let new_workers = list.append(workers, [#(n, actor.data)])
      //recurse until n actors have been made
      start_workers(n - 1, topology, algorithm, new_workers, monitor)
    }
    False -> {
      //once all actors have been created, set up topology
      assign_neighbors(list.length(workers), topology, workers)
      workers
    }
  }
}

pub fn assign_neighbors(
  n: Int,
  topology: String,
  actors: List(#(Int, Subject(Message))),
) {
  case n {
    //if n=0, we are done, else treat the current actor
    0 -> io.println("full topology created")
    _ -> {
      //get nth actor
      let assert Ok(result) = list.find(actors, fn(x) { pair.first(x) == n })
      let subject = pair.second(result)
      //send neighbors to actor based on topology
      case topology {
        "full" -> {
          //actor gets every actor as neighbor except itself
          actor.send(
            subject,
            NeighborSetUp(list.filter(actors, fn(x) { x.0 != n })),
          )
        }
        "3D" -> {
          let neighbors = get_3d_neighbors(n, actors)
          actor.send(subject, NeighborSetUp(neighbors))
        }
        "line" -> {
          actor.send(
            subject,
            NeighborSetUp(
              list.filter(actors, fn(x) { x.0 == n + 1 || x.0 == n - 1 }),
            ),
          )
        }
        "imp3D" -> io.println("imperfect 3d topology")
        //TODO: 3d grid, plus one extra random neighbor each
        _ -> io.println("invalid topology input")
      }

      //recurse with next neighbor
      assign_neighbors(n - 1, topology, actors)
    }
  }
}

pub fn get_3d_neighbors(
  n: Int,
  actors: List(#(Int, Subject(Message))),
) -> List(#(Int, Subject(Message))) {
  //get coordinates of node in matrix
  let num_actors = list.length(actors)
  let grid_size = float.power(int.to_float(num_actors), 1.0 /. 3.0)
  let grid_int = float.round(result.unwrap(grid_size, 0.0))
  let #(x, y, z) = num_to_coords(n, grid_int)

  //find neighbors in each direction
  let candidates = [
    #(x - 1, y, z),
    #(x + 1, y, z),
    #(x, y - 1, z),
    #(x, y + 1, z),
    #(x, y, z - 1),
    #(x, y, z + 1),
  ]

  let neighbors =
    list.filter_map(candidates, fn(x) {
      let #(nx, ny, nz) = x
      //filter out invalid coordinates
      case
        nx >= 0
        && ny >= 0
        && nz >= 0
        && nx < grid_int
        && ny < grid_int
        && nz < grid_int
      {
        True -> {
          //find the neighbor's index
          let num = coords_to_num(x, grid_int)
          case list.find(actors, fn(x) { pair.first(x) == num - 1 }) {
            //neighbor gets added to neighbors list
            Ok(actor) -> Ok(actor)
            Error(_) -> Error(Nil)
          }
        }
        False -> Error(Nil)
      }
    })
  neighbors
}

pub fn get_imp3d_neighbors(
  n: Int,
  actors: List(#(Int, Subject(Message))),
) -> List(#(Int, Subject(Message))) {
  //get the regular 3d grid neighbors
  let reg_neighbors = get_3d_neighbors(n, actors)
  //get list of other options to add
  let others =
    list.filter(actors, fn(actor) {
      //any actor not already in neighbors list
      !list.contains(reg_neighbors, actor)
    })
  //pick a random candidate to add
  let rando = find_random_neighbor(others)

  list.append(reg_neighbors, [rando])
}

pub fn num_to_coords(n: Int, size: Int) -> #(Int, Int, Int) {
  //convert n to coordinates in 3d grid
  let x = { n - 1 } % size
  let y = { { n - 1 } / size } % size
  let z = n / { size * size }

  #(x, y, z)
}

pub fn coords_to_num(coords: #(Int, Int, Int), size: Int) -> Int {
  //convert coordinates in grid to node number
  let #(x, y, z) = coords
  1 + x + y * size + z * size * size
}

fn find_random_actor(
  list: List(#(Int, Subject(Message))),
  n: Int,
) -> process.Subject(Message) {
  let rando = int.random(n) + 1
  let assert Ok(result) = list.find(list, fn(x) { pair.first(x) == rando })
  pair.second(result)
}

fn find_random_neighbor(
  list: List(#(Int, Subject(Message))),
) -> #(Int, Subject(Message)) {
  let num_actors = list.length(list)
  let rando = int.random(num_actors)
  let assert Ok(result) = list.find(list, fn(x) { pair.first(x) == rando })
  result
}

pub fn rand_neighbor(
  list: List(#(Int, Subject(Message))),
) -> process.Subject(Message) {
  let size = list.length(list)
  let rando = int.random(size) + 1
  let index_split = list.take(list, rando)
  let assert Ok(neighbor) = list.last(index_split)
  neighbor.1
}
