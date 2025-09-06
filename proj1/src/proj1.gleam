//import gleam/bool
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/otp/actor

pub fn main() -> Nil {
  let n = 40
  let k = 24

  let assert Ok(controller) =
    actor.new(n)
    |> actor.on_message(handle_message_controller)
    |> actor.start

  actor.send(controller.data, Start(n, k, controller.data))

  while_true(controller.data)
}

pub fn while_true(supervisor: Subject(Message)) {
  case actor.call(supervisor, waiting: 100, sending: Get) == 0 {
    True -> Nil
    False -> {
      while_true(supervisor)
    }
  }
}

pub type Message {
  Start(Int, Int, Subject(Message))
  Print(Int, Int)
  Get(Subject(Int))
}

pub fn handle_message_controller(
  state: Int,
  message: Message,
) -> actor.Next(Int, Message) {
  case message {
    Start(n, k, subject) -> {
      let assert Ok(starter) =
        actor.new(n)
        |> actor.on_message(starter_handler)
        |> actor.start
      actor.send(starter.data, SpinUp(n, k, subject))
      echo "started with " <> int.to_string(state) <> " jobs"
      actor.continue(state)
    }
    Print(i, sum) -> {
      let check = perfect_square(sum)
      case check {
        True -> io.println("Result " <> int.to_string(i))
        False -> Nil
      }
      echo "new state " <> int.to_string(state - 1)
      actor.continue(state - 1)
    }
    Get(reply) -> {
      actor.send(reply, state)
      actor.continue(state)
    }
  }
  actor.continue(state)
}

pub type Starter {
  SpinUp(Int, Int, Subject(Message))
}

pub fn starter_handler(state: Int, message: Starter) -> actor.Next(Int, Starter) {
  case message {
    SpinUp(n, k, supervisor) -> {
      create_worker(n, k, supervisor)
      actor.continue(state)
    }
  }
}

pub fn create_worker(n: Int, k: Int, supervisor: Subject(Message)) -> Nil {
  case n > 0 {
    True -> {
      let assert Ok(actor) =
        actor.new(False)
        |> actor.on_message(handle_message_worker)
        |> actor.start

      actor.send(actor.data, Sum(n + k - 1, k, n, supervisor))
      echo "Created worker for n = " <> int.to_string(n)
      create_worker(n - 1, k, supervisor)
    }
    False -> {
      Nil
    }
  }
}

pub type Msg {
  Sum(Int, Int, Int, Subject(Message))
}

pub fn handle_message_worker(state: Bool, message: Msg) -> actor.Next(Bool, Msg) {
  case message {
    Sum(n, l, worker, supervisor) -> {
      let sum = sum_of_squares_for_range(n, l, worker)
      echo "sum for worker "
        <> int.to_string(worker)
        <> " = "
        <> int.to_string(sum)
      actor.send(supervisor, Print(n - l + 1, sum))
      echo "Sent actor info for worker " <> int.to_string(worker)
      actor.continue(state)
    }
  }
}

pub fn sum_of_squares_for_range(n: Int, l: Int, worker: Int) -> Int {
  case l {
    0 -> 0
    _ -> {
      echo "squaring num "
        <> int.to_string(n)
        <> " where l is "
        <> int.to_string(l)
        <> " and worker is "
        <> int.to_string(worker)
      let sqr = n * n
      sqr + sum_of_squares_for_range({ n - 1 }, { l - 1 }, worker)
    }
  }
}

pub fn perfect_square(n: Int) -> Bool {
  echo "checking if sum is perfect square"
  let sq_rt = float.square_root(int.to_float(n))
  case sq_rt {
    Ok(num) -> {
      float.floor(num) == num
    }
    Error(_) -> False
  }
}
