defmodule MauricioTest.CatChat do
  use ExUnit.Case

  alias Mauricio.CatChat
  alias Mauricio.CatChat.{Chat, Chats}
  alias Mauricio.CatChat.Cat
  alias MauricioTest.Helpers
  alias Mauricio.Text

  setup do
    {:ok, _} = :bookish_spork.start_server()
    on_exit(&:bookish_spork.stop_server/0)

    {:ok, %{}}
  end

  test "create new chat then shutdown" do
    {:noreply, nil} = CatChat.handle_cast({:process_update, Helpers.start_update}, nil)
    assert Registry.count(Chat.registry_name) == 1
    assert DynamicSupervisor.count_children(Chats) == %{active: 1, specs: 1, supervisors: 0, workers: 1}

    {:noreply, nil} = CatChat.handle_cast({:process_update, Helpers.stop_update}, nil)
    assert Registry.count(Chat.registry_name) == 0
    assert DynamicSupervisor.count_children(Chats) == %{active: 0, specs: 0, supervisors: 0, workers: 0}
  end

  test "start chat sequence" do
    chat_id = 11
    m = fn text -> Helpers.message_with_text(chat_id, text) end

    {:noreply, state} = Chat.handle_continue(:start, chat_id)
    Helpers.assert_capture_expected_text(Text.get_text(:start))
    dialog = [
      {m.("Chertik"), "<i>Котeйке нравится имя Chertik</i>\n"}
    ]
    Helpers.assert_dialog(state, dialog)
    bad_dialog = [
      {m.(""), "<i>Котик решил, что будет зваться Мяурицио</i>\n"}
    ]
    %{cat: %Cat{name: name}} = Helpers.assert_dialog(state, bad_dialog)
    assert name == Application.get_env(:mauricio, :default_name)
  end

end

defmodule MauricioTest.CatChat.ResponseProcessing do
  use ExUnit.Case

  alias Mauricio.Text
  alias Mauricio.CatChat.{Cat, Member, Chat}
  alias Mauricio.CatChat.Chat.Responses
  alias MauricioTest.Helpers

  setup do
    {:ok, _} = :bookish_spork.start_server()
    on_exit(&:bookish_spork.stop_server/0)

    {:ok, %{}}
  end

  test "process response from cat reation" do
    chat_state = Chat.new_state(1, Helpers.message_with_text(1, "1"), "Cat")
    who = chat_state[:members][1]
    cat = chat_state[:cat]
    cat_satiety = cat.satiety

    fast_trigger = fn trigger ->
      Cat.react_to_triggers(cat, who, [trigger])
      |> List.wrap()
      |> Responses.process_responses(chat_state)
    end

    st = fast_trigger.(:banish)
    Helpers.assert_capture_expected_text(Text.get_text(:banished, cat: cat, who: who))
    assert st[:members][who.id].participant? == false

    st = fast_trigger.(:eat)
    Helpers.assert_capture_expected_text(:any)
    assert st[:cat].satiety == cat_satiety + 1

    _st = fast_trigger.(:mew)
    Helpers.assert_capture_expected_text(:any)

    _st = fast_trigger.(:cat)
    Helpers.assert_capture_photo_or_animation()

  end

  test "process response from command" do
    state = Chat.new_state(1, Helpers.message_with_text(1, "1"), "Cat")
    who = state[:members][1]
    %Cat{
      times_pet: times_pet,
      laziness: laziness
    } = cat = state[:cat]


    message = fn text -> Helpers.message_with_text(1, text) end

    Chat.process_message(message.("/hug"), state)
    Helpers.assert_capture_expected_text(:any)

    st = Chat.process_message(message.("/pet"), state)
    Helpers.assert_capture_expected_text(:any)
    assert st[:cat].times_pet == times_pet + 1

    st = Chat.process_message(message.("/become_lazy"), state)
    Helpers.assert_capture_expected_text(:any)
    assert st[:cat].laziness == laziness * 2

    st = Chat.process_message(message.("/become_annoying"), state)
    Helpers.assert_capture_expected_text(:any)
    assert st[:cat].laziness == round(laziness / 2)
  end

end