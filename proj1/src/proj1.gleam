//import gleam/bool
import gleam/erlang/process.{type Subject}

//import gleam/float
import gleam/int
import gleam/io
import gleam/result

//import gleam/list
import gleam/otp/actor

pub fn main() -> Nil {
  echo result.unwrap(int.square_root(25), 0.0) == 5.0
  Nil
  //let num = 3
  //let size = 2
  //let assert Ok(controller) =
  //actor.new(0)
  //|> actor.on_message(handle_message_controller)
  //|> actor.start
  //actor.send(controller.data, Start(num, size - 1))
  //assert actor.call(controller.data, waiting: 20, sending: Get) == 0
}

pub fn create_worker(n: Int, k: Int) -> Nil {
  case n > 0 {
    True -> {
      let assert Ok(actor) =
        actor.new(0)
        |> actor.on_message(handle_message_worker)
        |> actor.start

      actor.send(actor.data, Sum(n, k))
      io.println("Created worker for n = " <> int.to_string(n))
      let val = n - 1
      create_worker(val, k)
    }
    False -> {
      Nil
    }
  }
}

pub fn sum_of_squares_for_range(n: Int, l: Int) -> Int {
  case l {
    0 -> 0
    _ -> {
      let sqr = n * n
      sqr + sum_of_squares_for_range({ n - 1 }, { l - 1 })
    }
  }
}

pub fn handle_message_controller(
  state: Int,
  message: Message,
) -> actor.Next(Int, Message) {
  case message {
    Start(n, k) -> {
      create_worker(n, k)
      let state = n
      actor.continue(state)
    }
    Print(i, val) -> {
      case val {
        True -> {
          io.println(int.to_string(i))
        }
        False -> {
          Nil
        }
      }
      let state = state - 1
      actor.continue(state)
    }
    Get(reply) -> {
      actor.send(reply, state)
      actor.continue(state)
    }
  }
  actor.continue(state)
}

pub fn perfect_square(n: Int) -> Bool {
  let res = int.square_root(n)
  result.unwrap(res, 0.0) == 0.0
  //float.subtract(sqr_rt, float.floor(sqr_rt)) == 0.0
}

pub fn handle_message_worker(state: Int, message: Msg) -> actor.Next(Int, Msg) {
  case message {
    Sum(n, l) -> {
      //let result = sum_squares(n, l)
      //actor.send(controller.data, Print(l, result))
      actor.continue(state)
    }
  }
}

pub type Message {
  Start(Int, Int)
  Print(Int, Bool)
  Get(Subject(Int))
}

pub type Msg {
  Sum(Int, Int)
}
