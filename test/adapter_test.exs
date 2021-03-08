defmodule MauricioTest.Adapter do
  use ExUnit.Case
  alias Mauricio.News.Adapter.Panorama

  test "panorama transfrom" do
    f = File.read!("test/test_data/panorama.html")
    {:ok, doc} = Floki.parse_document(f)

    assert [
             {_,
              "В Европарламенте призвали пересмотреть формат 8 марта из-за \"пропаганды бинарной гендерной системы\"",
              "/news/v-evroparlamente-prizvali-peresmotret-format-8-marta-iz-za-propagandy-binarnoj-gendernoj-sistemy"},
             {_,
              "В Белоруссии заблокируют YouTube за отказ продвигать в тренды двухчасовой фильм о планах Запада по срыву посевной",
              "/news/v-belorussii-zablokiruyut-youtube-za-otkaz-prodvigat-v-trendy-dvuxchasovoj-film-o-planax-zapada-po-sryvu-posevnoj"},
             {_, "Лукашенко объявил о проведении новых президентских выборов по почте",
              "/news/lukashenko-obyavil-o-provedenii-novyx-prezidentskix-vyborov-po-pochte"},
             {_,
              "Китайский министр получил 20 лет тюрьмы после того, как у его родителей нашли квартиру в Пекине",
              "/news/p43888"},
             {_,
              "«Вы обещали, что против меня майданов не будет»: Пашинян подал в суд на Джорджа Сороса",
              "/news/pashinyan-podal-v-sud-na-dzhordzha-sorosa"},
             {_, "ЕС потребовал добавить в мультфильм «Маша и медведи» ЛГБТ-персонажей",
              "/news/es-potreboval-dobavit-v-multfilm-masha-i-medvedi-lgbt-personazhej"},
             {_,
              "Цисгендерный казачий отряд Виталия Милонова задержал квирфеминистку, небинарного гея и одного нелегального мигранта на праздновании 8 марта",
              "/news/czisgendernyj-kazachij-otryad-vitaliya-milonova-zaderzhal-kvirfeministku-nebinarnogo-geya-i-odnogo-nelegalnogo-migranta-na-prazdnovanii-8-marta"},
             {_,
              "Калининградские таможенники поздравили женщин с 8 марта, раздавив на бульдозере партию санкционных цветов в виде цифры 8",
              "/news/kaliningradskie-tamozhenniki-pozdravili-zhenshhin-s-8-marta-razdaviv-na-buldozere-partiyu-sankczionnyx-czvetov-v-vide-czifry-8"},
             {_, "Суд признал лицо Залины Маршенкуловой овальным",
              "/news/sud-priznal-liczo-zaliny-marshenkulovoj-ovalnym"},
             {_, "Ивановские феминистки на 8 Марта сожгли цветочные магазины",
              "/news/ivanovskie-feministki-na-8-marta-sozhgli-czvetochnye-magaziny"},
             {_, "Илон Маск презентовал не требующий энергии подземный эко-холодильник",
              "/news/ilon-mask-prezentoval-ne-trebuyushhij-energii-podzemnyj-eko-xolodilnik"},
             {_, "Роботы Boston Dynamics создали профсоюз",
              "/news/roboty-boston-dynamics-sozdali-profsoyuz"},
             {_,
              "Директор Европейского института генетики: «Только расист может говорить, что наука чем-то обязана белым мышам»",
              "/news/direktor-evropejskogo-instituta-genetiki"},
             {_, "В Сколково разработали нано-дисплей, реагирующий на прикосновение пальца",
              "/news/p40517"},
             {_,
              "«Роскосмос» снабдит космонавтов инструкцией на случай вселения демонов в иностранных членов экипажа",
              "/news/roskosmos-snabdit-kosmonavtov-instrukcziej"},
             {_, "Россия введёт санкции на ввоз европейского семенного картофеля ",
              "/news/rossiya-vvedyot-sankczii-na-vvoz-i-prodazhu-evropejskogo-semennogo-kartofelya"},
             {_, "Чубайс призвал россиян вкладываться в биткоин",
              "/news/chubajs-prizval-rossiyan-vkladyvatsya-v-bitkoin"},
             {_, "На банкноте номиналом 15 рублей будет изображён Лахта-центр",
              "/news/na-banknote-nominalom-15-rublej-budet-izobrazhyon-laxta-czentr"},
             {_,
              "Тринадцать польских аквалангистов пострадали при попытке демонтажа «Северного потока-2»",
              "/news/trinadczat-polskix-akvalangistov-postradali-pri-popytke-demontazha-severnogo-potoka-2"},
             {_, "Adidas выпустит партию специальных спортивных костюмов для пациентов больниц",
              "/news/adidas-vypustit-partiyu"},
             {_, "ЕСПЧ восстановил в служении схиигумена Сергия",
              "/news/espch-vosstanovil-v-sluzhenii-sxiigumena-sergiya"},
             {_, "В Сколково разработали инновационную лопату для жарки блинов",
              "/32336-v-skolkovo-razrabotali.html"},
             {_, "В Смоленске на Масленицу сожгли чучело Навального",
              "/news/v-smolenske-na-masleniczu-sozhgli-chuchelo-navalnogo"},
             {_,
              "Прогрессивные СМИ бьют тревогу из-за возможного роста наркофобии после новосибирского инцидента",
              "/news/progressivnye-rossijskie-smi-byut-trevogu-iz-za-vozmozhnogo-rosta-narkofobii-posle-novosibirskogo-inczidenta"},
             {_,
              "МВД пообещало 8 марта не реагировать на все сообщения о домашнем насилии женщин в отношении мужчин",
              "/news/mvd-poobeshhalo-8-marta-ne-reagirovat-na-vse-soobshheniya-o-domashnem-nasilii-zhenshhin-v-otnoshenii-muzhchin"},
             {_,
              "Вася Обломов не смог стать почётным гражданином Магаданской области из-за отсутствия судимости",
              "/news/vasya-oblomov-ne-smog-stat-pochyotnym-grazhdaninom-magadanskoj-oblasti-iz-za-otsutstviya-sudimosti"}
           ] = Panorama.transform(doc)
  end
end
