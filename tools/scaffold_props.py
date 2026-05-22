"""
One-shot scaffolder for new room props.
Creates folder + prop_<name>.gd + prop_<name>.tscn + placeholder.png for each prop.
Safe to delete after running.
"""

import os
from PIL import Image

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (name, room, classname, target_w, target_h, click_line, right_line, special)
PROPS = [
    ("umbrella_stand", "entrance_hall", "UmbrellaStand", 18, 44,
     "An umbrella stand. Empty — must have been a sunny week.",
     "A wrought-iron umbrella stand near the door.", None),
    ("chandelier", "entrance_hall", "Chandelier", 48, 24,
     "A dusty chandelier hangs above. Half the bulbs are out.",
     "Crystal chandelier. It hasn't been cleaned in years.", None),
    ("armchair", "living_room", "Armchair", 40, 52,
     "A worn velvet armchair. Looks like someone sat here often.",
     "The cushions are pressed in. The owner had a favorite spot.", None),
    ("record_player", "living_room", "RecordPlayer", 36, 40,
     "An old record player. The vinyl on it reads: 'Nocturnes, Op. 9'.",
     "Vinyl and brass. A relic from another era.", None),
    ("wine_decanter", "living_room", "WineDecanter", 24, 40,
     "A half-empty wine decanter. The wine inside smells stale.",
     "Crystal decanter. Whoever drank from it left in a hurry.", None),
    ("desk_lamp", "study", "DeskLamp", 18, 36, None, None, "toggle_lamp"),
    ("typewriter", "study", "Typewriter", 56, 40,
     "A typewriter. There's a half-finished letter still in the carriage.",
     "Smith Corona, mid-century. The keys are jammed.", None),
    ("globe", "study", "Globe", 32, 44,
     "An old wooden globe. The borders look pre-war.",
     "Continents and faded colors. A traveler's globe.", None),
]


GD_TEMPLATE = '''# @popochiu-docs-ignore-class
@tool
extends PopochiuProp


func _on_click() -> void:
\tawait C.player.walk_to_clicked()
\tawait C.player.face_clicked()
\tawait C.player.say("{click_line}")


func _on_right_click() -> void:
\tawait C.player.say("{right_line}")
'''


GD_TEMPLATE_LAMP = '''# @popochiu-docs-ignore-class
@tool
extends PopochiuProp

var lamp_on := false


func _on_click() -> void:
\tawait C.player.walk_to_clicked()
\tawait C.player.face_clicked()
\tlamp_on = not lamp_on
\tif lamp_on:
\t\tawait C.player.say("Click. The lamp warms up, casting a soft pool of light.")
\telse:
\t\tawait C.player.say("Click. The lamp goes dark.")


func _on_right_click() -> void:
\tawait C.player.say("An old brass desk lamp. The switch still works.")
'''


TSCN_TEMPLATE = '''[gd_scene format=3 uid="uid://{scene_uid}"]

[ext_resource type="Script" path="res://game/rooms/{room}/props/{name}/prop_{name}.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://game/rooms/{room}/props/{name}/placeholder.png" id="tex_placeholder"]

[node name="{classname}" type="Area2D"]
script = ExtResource("1_script")
script_name = "{classname}"
description = "{display_name}"
cursor = 1
interaction_polygon = PackedVector2Array({polygon})

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
texture = ExtResource("tex_placeholder")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]

[node name="InteractionPolygon" type="CollisionPolygon2D" parent="."]
visible = false
modulate = Color(1, 1, 0, 1)
polygon = PackedVector2Array({polygon})

[node name="ObstaclePolygon" type="NavigationObstacle2D" parent="."]
visible = false
affect_navigation_mesh = true
carve_navigation_mesh = true
'''


def make_polygon(w, h):
    hw = w // 2
    hh = h // 2
    return f"{-hw}, {-hh}, {hw}, {-hh}, {hw}, {hh}, {-hw}, {hh}"


def make_display_name(name):
    return " ".join(word.capitalize() for word in name.split("_"))


def make_scene_uid(name):
    # Deterministic uid-like string based on name. Godot will accept and may regenerate on import.
    base = "".join(c for c in name if c.isalnum()).lower()
    return f"b{base}prop001"[:24]


def scaffold():
    created = []
    for name, room, classname, w, h, click_line, right_line, special in PROPS:
        prop_dir = os.path.join(BASE, "game", "rooms", room, "props", name)
        os.makedirs(prop_dir, exist_ok=True)

        # placeholder.png — transparent at the prop's target size
        png_path = os.path.join(prop_dir, "placeholder.png")
        if not os.path.exists(png_path):
            img = Image.new("RGBA", (w, h), (255, 0, 255, 64))  # tinted magenta so it's visible during dev
            img.save(png_path)
            created.append(png_path)

        # prop_<name>.gd
        gd_path = os.path.join(prop_dir, f"prop_{name}.gd")
        if special == "toggle_lamp":
            gd_content = GD_TEMPLATE_LAMP
        else:
            gd_content = GD_TEMPLATE.format(click_line=click_line, right_line=right_line)
        with open(gd_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(gd_content)
        created.append(gd_path)

        # prop_<name>.tscn
        tscn_path = os.path.join(prop_dir, f"prop_{name}.tscn")
        tscn_content = TSCN_TEMPLATE.format(
            scene_uid=make_scene_uid(name),
            room=room,
            name=name,
            classname=classname,
            display_name=make_display_name(name),
            polygon=make_polygon(w, h),
        )
        with open(tscn_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(tscn_content)
        created.append(tscn_path)

    print(f"Scaffolded {len(PROPS)} props ({len(created)} files written):")
    for p in created:
        rel = os.path.relpath(p, BASE).replace("\\", "/")
        print(f"  {rel}")


if __name__ == "__main__":
    scaffold()
