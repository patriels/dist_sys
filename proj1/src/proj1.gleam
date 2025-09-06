//import gleam/bool
import gleam/bool
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/result

//import gleam/list
import gleam/otp/actor

pub fn main() -> Nil {
  let n = 3
  let k = 2

  let assert Ok(controller) =
    actor.new(n)
    |> actor.on_message(handle_message_controller)
    |> actor.start

  actor.send(controller.data, Start(n, k, controller.data))
  assert actor.call(controller.data, waiting: 100, sending: Get) == 0
}

pub type Message {
  Start(Int, Int, Subject(Message))
  Print(Int, Bool)
  Get(Subject(Int))
}

pub fn handle_message_controller(
  state: Int,
  message: Message,
) -> actor.Next(Int, Message) {
  case message {
    Start(n, k, subject) -> {
      create_worker(n, k, subject)
      echo "started with " <> int.to_string(state) <> " jobs"
      actor.continue(state)
    }
    Print(i, val) -> {
      echo "current state " <> int.to_string(state)
      let update = state - 1
      case val {
        True -> io.println("Result " <> int.to_string(i))
        False -> Nil
      }
      echo "new state " <> int.to_string(update)
      actor.continue(update)
    }
    Get(reply) -> {
      echo "how many times is this hit?"
      actor.send(reply, state)
      actor.continue(state)
    }
  }
  actor.continue(state)
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

pub fn handle_message_worker(
  _state: Bool,
  message: Msg,
) -> actor.Next(Bool, Msg) {
  case message {
    Sum(n, l, worker, supervisor) -> {
      let sum = sum_of_squares_for_range(n, l, worker)
      echo "sum for worker "
        <> int.to_string(worker)
        <> " = "
        <> int.to_string(sum)
      let check = perfect_square(sum)
      echo "Calculated sum of squares for "
        <> int.to_string(n)
        <> " and it was "
        <> bool.to_string(check)
      actor.send(supervisor, Print(n - l + 1, check))
      actor.stop()
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
  let sqr_rt = result.unwrap(int.square_root(n), 0.0)
  float.subtract(sqr_rt, float.floor(sqr_rt)) == 0.0
}
