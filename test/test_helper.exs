ExUnit.start()

defmodule KatexTest.Helpers do

  import ExUnit.Assertions

  alias Nadia.Model.Update, as: NadiaUpdate
  alias Nadia.Model.Message, as: NadiaMessage
  alias Nadia.Model.Chat, as: NadiaChat
  alias Nadia.Model.User, as: NadiaUser

  alias Katex.CatChat.{Chat, Cat, Member}

  def start_update do
    update_with_text(1, "/start")
  end

  def stop_update do
    update_with_text(1, "/stop")
  end

  def update_with_text(chat_id, text) do
    %NadiaUpdate{
      callback_query: nil,
      channel_post: nil,
      chosen_inline_result: nil,
      edited_message: nil,
      inline_query: nil,
      message: message_with_text(chat_id, text),
      update_id: 555290602
    }
  end

  def message_with_text(chat_id, text) do
    %NadiaMessage{
      audio: nil,
      caption: nil,
      channel_chat_created: nil,
      chat: chat(chat_id),
      contact: nil,
      date: 1578194118,
      delete_chat_photo: nil,
      document: nil,
      edit_date: nil,
      entities: nil,
      forward_date: nil,
      forward_from: nil,
      forward_from_chat: nil,
      from: user(chat_id),
      group_chat_created: nil,
      left_chat_member: nil,
      location: nil,
      message_id: 1030,
      migrate_from_chat_id: nil,
      migrate_to_chat_id: nil,
      new_chat_member: nil,
      new_chat_photo: [],
      new_chat_title: nil,
      photo: [],
      pinned_message: nil,
      reply_to_message: nil,
      sticker: nil,
      supergroup_chat_created: nil,
      text: text,
      venue: nil,
      video: nil,
      voice: nil
    }
  end

  def chat(chat_id) do
    %NadiaChat{
      first_name: "Yaropolk",
      id: chat_id,
      last_name: "",
      photo: nil,
      title: nil,
      type: "private",
      username: "Zloe_Aloe",
    }
  end

  def user(chat_id) do
    %NadiaUser{
      first_name: "Yaropolk",
      id: chat_id,
      last_name: "",
      username: "Zloe_Aloe",
    }
  end

  def body_to_dict(body) do
    URI.query_decoder(body) |> Map.new()
  end

  def body_of_captured_request() do
    :bookish_spork.capture_request()
      |> elem(1)
      |> Map.fetch!(:body)
      |> body_to_dict()
  end

  def assert_capture_expected_text(expected_text) do
    request_text =
      body_of_captured_request()
      |> Map.fetch!("text")
    case expected_text do
      :any -> true
      text ->
        assert request_text == text
    end
  end

  def assert_capture_photo_or_animation() do
    body = body_of_captured_request()
    assert Map.has_key?(body, "photo") or Map.has_key?(body, "animation")
  end

  def assert_dialog(state, []) do
    state
  end

  def assert_dialog(state, [{message, response} | rest]) when not is_tuple(message) do
    assert_dialog(state, [{{:process_message, message}, response} | rest])
  end

  def assert_dialog(state, [{message, response} | rest]) do
    {:noreply, new_state} = Chat.handle_cast(message, state)
    assert_capture_expected_text(response)

    assert_dialog(new_state, rest)
  end

end
