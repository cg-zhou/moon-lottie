///|
test "parse_ripple_json" {
  let json_str =
    #|{
    #|  "v": "5.0.0",
    #|  "fr": 60,
    #|  "ip": 0,
    #|  "op": 361,
    #|  "w": 800,
    #|  "h": 600,
    #|  "nm": "ripple graph",
    #|  "assets": [
    #|    {
    #|      "id": "comp_78",
    #|      "layers": [
    #|        {
    #|          "ty": 0,
    #|          "nm": "grow bar",
    #|          "refId": "comp_79",
    #|          "ks": {
    #|            "o": {"a": 0, "k": 100},
    #|            "r": {"a": 0, "k": 0},
    #|            "p": {"a": 0, "k": [22, 290, 0]},
    #|            "a": {"a": 0, "k": [32, 205, 0]},
    #|            "s": {"a": 0, "k": [100, 100, 100]}
    #|          }
    #|        }
    #|      ]
    #|    },
    #|    {
    #|      "id": "comp_79",
    #|      "layers": [
    #|        {
    #|          "ty": 4,
    #|          "nm": "bar",
    #|          "ks": {
    #|            "o": {"a": 0, "k": 100},
    #|            "r": {"a": 0, "k": 0},
    #|            "p": {"a": 0, "k": [20, 205, 0]},
    #|            "a": {"a": 0, "k": [184, 392, 0]},
    #|            "s": {"a": 0, "k": [100, 100, 100]}
    #|          },
    #|          "shapes": [
    #|            {
    #|              "ty": "sh",
    #|              "ks": {
    #|                "a": 0,
    #|                "k": {
    #|                  "i": [[0, 0], [0, 0]],
    #|                  "o": [[0, 0], [0, 0]],
    #|                  "v": [[194, 233], [194, 553]],
    #|                  "c": false
    #|                }
    #|              }
    #|            },
    #|            {
    #|              "ty": "tm",
    #|              "s": {"a": 0, "k": 0},
    #|              "e": {"a": 0, "k": 100},
    #|              "o": {"a": 0, "k": 0},
    #|              "m": 1
    #|            },
    #|            {
    #|              "ty": "gs",
    #|              "o": {"a": 0, "k": 100},
    #|              "w": {"a": 0, "k": 2},
    #|              "g": {
    #|                "p": 5,
    #|                "k": {"a": 0, "k": [0, 0.63, 0.81, 0.92, 1, 1, 1, 1]}
    #|              },
    #|              "s": {"a": 0, "k": [258, 509]},
    #|              "e": {"a": 0, "k": [396, -25]},
    #|              "t": 1,
    #|              "lc": 1,
    #|              "lj": 1,
    #|              "ml": 4
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ],
    #|  "layers": [
    #|    {
    #|      "ty": 0,
    #|      "nm": "grow graph",
    #|      "refId": "comp_78",
    #|      "ks": {
    #|        "o": {"a": 0, "k": 100},
    #|        "r": {"a": 0, "k": 0},
    #|        "p": {"a": 0, "k": [411, 221, 0]},
    #|        "a": {"a": 0, "k": [400, 300, 0]},
    #|        "s": {"a": 0, "k": [-55, 55, 100]}
    #|      }
    #|    }
    #|  ]
    #|}

  let json = @json.parse(json_str)
  let ani = parse_animation(json) catch {
    e => fail("Failed to parse ripple.json: \{e}")
  }

  inspect(ani.version, content="5.0.0")
  match ani.assets {
    Some(assets) => inspect(assets.length(), content="2")
    None => fail("Assets should exist")
  }
  inspect(ani.layers.length(), content="1")

  match ani.layers[0].data {
    PreComp(ref_id, _, _) => inspect(ref_id, content="comp_78")
    _ => fail("Layer 0 should be a PreComp layer")
  }
}
