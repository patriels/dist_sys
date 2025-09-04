//import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/otp/actor

pub fn main() -> Nil {
  let _n = 5

  let assert Ok(controller) =
    actor.new(0)
    |> actor.on_message(handle_message_checker)
    |> actor.start

  actor.send(controller.data, Add(5))
  actor.send(controller.data, Check(5, True))
  // actor.call(controller.data, waiting: 20, sending: Get)

  io.println("Hello from proj1!")
}

//Checks if value is a perfect square
pub fn handle_message_checker(
  state: Int,
  message: Message,
) -> actor.Next(Int, Message) {
  case message {
    Add(i) -> {
      let state = state + i
      echo state
      actor.continue(state)
    }
    Check(i, val) -> {
      let state = case val {
        True -> {
          i - 1
        }
        False -> {
          i + 1
        }
      }
      echo state
      actor.continue(state)
    }
  }
}

pub type Message {
  Add(Int)
  Check(Int, Bool)
  //Get(Subject(Int))
}
