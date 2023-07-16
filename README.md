# [IC] ANew Bundles

Плагин позволяет создавать наборы предметов, которые можно выдавать через бонусное меню ANew.

## Требования

- AmxModX версии 1.9.0 или новее;
- ItemsController из [VipModular](https://github.com/ArKaNeMaN/amxx-VipModular-pub/releases) (Ядро не требуется).

## Настройка

Создавать наборы можно двумя способами:
- Один набор - один файл
- Все наборы в одном файле

Можно использовать одновременно оба способа.

[Подробнее о структуре предметов для ItemsController...](https://github.com/ArKaNeMaN/amxx-VipModular-pub/blob/master/readme/items.md)

### Способ первый

Для создания набора первым способом необходимо создать файл с расширением `.json` в папке `amxmodx/configs/plugins/ItemsController/AnewBundles/Bundles` и указать в нём список нужных предметов. Название файла без `.json` будет являться названием набора. В файле должен находится либо массив предметов, либо один предмет.

Например, файл `.../Bundles/TestBundle.json`:
```jsonc
[
    {
        "Type": "Weapon",
        "Name": "weapon_deagle"
    },
    {
        "Type": "Weapon",
        "Name": "weapon_m4a1"
    }
]
```

Пример использования набора:
```ini
<call>
plugin = IC-AnewBundles.amxx
name = Тестовый бонус
function = GiveBundle
flags = TestBundle
points = 5
```

### Способ второй

Для создания наборов вторым способом необходимо указывать их в файле `amxmodx/configs/plugins/ItemsController/AnewBundles/Bundles.json`. В файле находится один JSON-обьект, ключи которого являются названиями наборов, а значения - самими наборами. Набор может быть представлен как массив предметов или как один предмет.

`.../Bundles.json`:
```jsonc
{
    "deagle_ak47": [
        {
            "Type": "Weapon",
            "Name": "weapon_deagle"
        },
        {
            "Type": "Weapon",
            "Name": "weapon_ak47"
        }
    ],
    "m4a1": {
        "Type": "Weapon",
        "Name": "weapon_m4a1"
    }
}
```

Пример использования наборов:
```ini
<call>
plugin = IC-AnewBundles.amxx
name = Тестовый бонус 1
function = GiveBundle
flags = deagle_ak47
points = 5

<call>
plugin = IC-AnewBundles.amxx
name = Тестовый бонус 2
function = GiveBundle
flags = deagle_m4a1
points = 5
```
