defmodule MauricioTest.CatChat do
  use ExUnit.Case

  alias Mauricio.CatChat
  alias Mauricio.CatChat.{Chat, Chats, Cat}
  alias Mauricio.Text
  alias Mauricio.Storage

  alias MauricioTest.Helpers
  alias MauricioTest.TestData

  setup do
    {:ok, _} = :bookish_spork.start_server()
    on_exit(&:bookish_spork.stop_server/0)

    Chats.stop_all_chats()
    Storage.flush()

    {:ok, %{}}
  end

  def assert_currently_n_chats(n) do
    assert DynamicSupervisor.count_children(Chats) == %{active: n, specs: n, supervisors: 0, workers: n}
  end

  test "create new chat then shutdown then again" do
    assert_currently_n_chats(0)

    :ok = CatChat.process_update(Helpers.start_update)
    assert_currently_n_chats(1)

    :ok = CatChat.process_update(Helpers.stop_update)
    assert_currently_n_chats(0)

    :ok = CatChat.process_update(Helpers.start_update)
    assert_currently_n_chats(1)

    :ok = CatChat.process_update(Helpers.stop_update)
    assert_currently_n_chats(0)
  end

  test "start from stored state" do
    chats = TestData.produce_n_uniq_chats(5)
    assert_currently_n_chats(0)

    Enum.each(chats, &Storage.put/1)

    CatChat.handle_continue(:load_chats, nil)
    assert_currently_n_chats(5)
  end
end

defmodule MauricioTest.CatChat.ResponseProcessing do
  use ExUnit.Case

  alias Mauricio.{Text, Storage}
  alias Mauricio.CatChat.{Cat, Chat, Chats}
  alias Mauricio.CatChat.Chat.Responses

  alias MauricioTest.Helpers

  setup do
    {:ok, _} = :bookish_spork.start_server()
    on_exit(&:bookish_spork.stop_server/0)

    Chats.stop_all_chats()
    Storage.flush()

    {:ok, %{}}
  end

  test "process response from cat reation" do
    chat_state = Chat.new_state(1, Helpers.message_with_text(1, "1"), "Cat")
    who = chat_state.members[1]
    cat = chat_state.cat
    cat_satiety = cat.satiety

    fast_trigger = fn cat, triggers ->
      Cat.react_to_triggers(cat, who, triggers)
      |> List.wrap()
      |> Responses.process_responses(chat_state)
    end

    st = fast_trigger.(cat, [:banish])
    Helpers.assert_capture_expected_text(Text.get_text(:banished, cat: cat, who: who))
    assert st.members[who.id].participant? == false

    st = fast_trigger.(cat, [:eat])
    Helpers.assert_capture_expected_text(:any)
    assert st.cat.satiety == cat_satiety + 1

    _st = fast_trigger.(cat, [:mew])
    Helpers.assert_capture_expected_text(:any)

    _st = fast_trigger.(cat, [:cat])
    Helpers.assert_capture_photo_or_animation()

    cat = %{cat | state: Cat.State.Away.new()}
    st = fast_trigger.(cat, [:loud, :eat])
    Helpers.assert_capture_expected_text(Text.get_text(:away_dinner_call, cat: cat, who: who))
    assert st.cat.state == Cat.State.Awake.new()
  end

  test "process response from command" do
    state = Chat.new_state(1, Helpers.message_with_text(1, "1"), "Cat")

    %Cat{
      times_pet: times_pet,
      laziness: laziness
    } = state.cat
    message = fn text -> Helpers.message_with_text(1, text) end

    Chat.process_message(message.("/hug"), state)
    Helpers.assert_capture_expected_text(:any)

    st = Chat.process_message(message.("/pet"), state)
    Helpers.assert_capture_expected_text(:any)
    assert st.cat.times_pet == times_pet + 1

    st = Chat.process_message(message.("/become_lazy"), state)
    Helpers.assert_capture_expected_text(:any)
    assert st.cat.laziness == laziness * 2

    st = Chat.process_message(message.("/become_annoying"), state)
    Helpers.assert_capture_expected_text(:any)
    assert st.cat.laziness == round(laziness / 2)
  end
end

defmodule MauricioTest.CatChat.Interaction do
  use ExUnit.Case

  alias Mauricio.{Storage, CatChat}
  alias Mauricio.CatChat.{Cat, Member, Chats}
  alias Mauricio.Text
  alias Mauricio.CatChat.Chat.Interaction

  alias MauricioTest.Helpers

  setup do
    {:ok, _} = :bookish_spork.start_server()
    on_exit(&:bookish_spork.stop_server/0)

    Chats.stop_all_chats()
    Storage.flush()

    {:ok, %{}}
  end

  describe "add to feeder" do
    setup do
      member = Member.new("A", "B", 1, 1, true)
      s = %{cat: Cat.new("C"), feeder: :queue.new()}
      %{member: member, s: s}
    end

    test "added nothing", %{member: member, s: s} do
      expected_text = Text.get_text(:added_nothing, who: member)
      {f, nil, message} = Interaction.handle_command("/add_to_feeder", member, s)
      assert :queue.is_empty(f)
      assert message == expected_text
      {f, nil, message} = Interaction.handle_command("/add_to_feeder ", member, s)
      assert :queue.is_empty(f)
      assert message == expected_text
    end

    test "added cat itself", %{member: member, s: s} do
      expected_text = Text.get_text(:added_self, who: member)
      {f, nil, message} = Interaction.handle_command("/add_to_feeder@kotyarabot", member, s)
      assert :queue.is_empty(f)
      assert message == expected_text
    end

    test "added something", %{member: member, s: s} do
      {f, nil, _m} = Interaction.handle_command("/add_to_feeder еда ", member, s)
      assert {:value, "еда"} == :queue.peek(f)
      {f, nil, _m} = Interaction.handle_command("/add_to_feederfood", member, s)
      assert {:value, "food"} == :queue.peek(f)
      {f, nil, _m} = Interaction.handle_command("/add_to_feedervery tasty food", member, s)
      assert {:value, "very tasty food"} == :queue.peek(f)
    end

    test "added a very long name", %{member: member, s: s} do
      food_name = """
      Lorem ipsum dolor sit amet, sagittis fusce pulvinar pellentesque suscipit id amet, quisque tortor, lacus lectus nunc et fugit gravida et, fusce orci adipiscing nulla vitae id.
      Aliquam natoque vel, ornare ut tincidunt nullam odio, ipsum vestibulum ullamcorper dignissim urna vestibulum vivamus, vivamus condimentum vehicula mollis eget ut.
      A a eget nam nec, at nunc adipiscing turpis aenean volutpat, massa fringilla, vel ut, bibendum et vel ac justo ipsum blandit.
      In non nec rutrum, neque porttitor eros dapibus. Accumsan nullam sit nullam malesuada, porta laoreet nam interdum gravida, vel venenatis amet amet dolor urna tellus.
      Ipsum sed scelerisque nonummy velit, magna accumsan non a eu, felis augue malesuada non etiam duis, nec fusce ut velit vestibulum nam donec, nam quis morbi.
      Consectetuer tellus in aut mauris ipsum, eros consectetuer amet nulla. Fermentum varius neque, pellentesque donec non a leo lectus, ridiculus sit auctor tellus vestibulum facilisis eleifend.
      Sapien id purus mattis, non hymenaeos rutrum neque sed, elementum amet odio egestas et non mauris.
      Eu sit at tortor commodo eu, dolor wisi in egestas suscipit non lorem, et turpis in, diam eget sit imperdiet pellentesque, proin dui sed orci.
      """

      {f, nil, _m} = Interaction.handle_command("/add_to_feeder" <> " " <> food_name, member, s)
      assert {:value, food_name} == :queue.peek(f)
    end

    test "feeder overflow", %{member: member, s: %{cat: c}} do
      f = :queue.from_list(~w(1 2 3 4 5))
      {f, nil, _m} = Interaction.handle_command("/add_to_feeder 6", member, %{cat: c, feeder: f})
      feeder_content_message = Text.get_text(:feeder_content, all_food: :queue.to_list(f))
      assert :queue.member("6", f)
      refute :queue.member("1", f)
      refute String.contains?(feeder_content_message, "1")
    end
  end

  test "multiuser chat" do
    :ok = CatChat.process_update(Helpers.start_update())
    :ok = CatChat.process_update(Helpers.update_with_text(1, "Валера"))

    second_member_message = Helpers.update_with_text(1, 2, "123")
    assert second_member_message.message.from.id == 2

    :ok = CatChat.process_update(second_member_message)
    {:ok, state} = Storage.fetch(1)
    assert state.members[1].participant?
    assert Map.has_key?(state.members, 2)
    assert state.members[2].participant?

    :ok = CatChat.process_update(Helpers.update_with_text(1, 2, "Брысь"))
    {:ok, state} = Storage.fetch(1)
    assert state.members[1].participant?
    assert not state.members[2].participant?

    :ok = CatChat.process_update(Helpers.stop_update())
  end
end
