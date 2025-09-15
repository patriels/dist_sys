import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/pair

pub fn main() -> Nil {
  let assert Ok(act1) =
    actor.new(0) |> actor.on_message(actor_handler) |> actor.start
  let assert Ok(act2) =
    actor.new(0) |> actor.on_message(actor_handler) |> actor.start
  let assert Ok(act3) =
    actor.new(0) |> actor.on_message(actor_handler) |> actor.start
  let assert Ok(act4) =
    actor.new(0) |> actor.on_message(actor_handler) |> actor.start
  let actors = [
    #(1, act1.data),
    #(2, act2.data),
    #(3, act3.data),
    #(4, act4.data),
  ]
  let rando = clamp_random(int.random(4))
  let subject = find_random_actor(actors)
  actor.send(subject, Ping(rando))
  io.println("Hello from project2!")
  let _hey = while_true(True)
  Nil
}

//pub fn validate_num_nodes(arg)
pub fn while_true(check: Bool) -> Bool {
  case check {
    True -> while_true(True)
    False -> while_true(False)
  }
}

pub fn clamp_random(num: Int) -> Int {
  case num {
    0 -> 1
    _ -> num
  }
}

pub fn find_random_actor(
  list: List(#(Int, process.Subject(Message))),
) -> process.Subject(Message) {
  let rando = clamp_random(int.random(4))
  let assert Ok(result) = list.find(list, fn(x) { pair.first(x) == rando })
  pair.second(result)
}

pub type Message {
  Ping(Int)
}

pub fn actor_handler(state: Int, message: Message) -> actor.Next(Int, Message) {
  case message {
    Ping(id) -> {
      io.println("My actor is " <> int.to_string(id))
      actor.continue(state)
    }
  }
}
