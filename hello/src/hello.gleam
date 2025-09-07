import argv
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/otp/actor.{type Builder, type StartError}
import gleam/otp/static_supervisor.{type Supervisor} as supervisor
import gleam/otp/supervision
import gleam/result

pub fn main() {
  let args = argv.load()
  echo args.arguments
  let params = result.unwrap(list.rest(args.arguments), [])
  case params == [] {
    True -> echo "wtf?"
    False -> {
      let n =
        result.unwrap(int.parse(result.unwrap(list.first(params), "0")), 0)
      let k = result.unwrap(int.parse(result.unwrap(list.last(params), "0")), 0)
      echo "n = " <> int.to_string(n) <> " and k = " <> int.to_string(k)
    }
  }

  let child_spec =
    supervision.ChildSpecification(
      start: fn() {
        actor.new(0)
        |> actor.on_message(handle_message)
        |> actor.start
      },
      restart: supervision.Permanent,
      significant: False,
      child_type: supervision.Worker(5000),
    )
  let _builder =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(child_spec)

  let assert Ok(_super) =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(child_spec)
    |> supervisor.start()

  // Start an actor
  let assert Ok(actor) =
    actor.new(0)
    |> actor.on_message(handle_message)
    |> actor.start

  let assert Ok(meh) =
    actor.new(0)
    |> actor.on_message(handle_message)
    |> actor.start

  // Send some messages to the actor
  actor.send(actor.data, Add(5))
  actor.send(actor.data, Add(3))
  actor.send(meh.data, Add(4))

  // Send a message and get a reply
  assert actor.call(actor.data, waiting: 20, sending: Get) == 8
}

pub fn handle_message(state: Int, message: Message) -> actor.Next(Int, Message) {
  case message {
    Add(i) -> {
      let state = state + i
      echo state
      actor.continue(state)
    }
    Get(reply) -> {
      actor.send(reply, state)
      actor.continue(state)
    }
  }
}

pub type Message {
  Add(Int)
  Get(Subject(Int))
}
