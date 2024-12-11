import std.file;
import std.json;

import bindbc.sdl;

import scene;
import entity;
import resourcemanager;

JSONValue dump(GameAttributes* attrib) {
    JSONValue j;
    j["title"] = attrib.title;
    j["window_width"] = attrib.window_width;
    j["window_height"] = attrib.window_height;
    j["opening_scene"] = attrib.opening_scene;
    return j;
}

JSONValue dump(Scene* scene) {
    JSONValue[] j_ui_arr;
    foreach(ui; scene.ui) {
        j_ui_arr ~= ui.dump();
    }

    JSONValue[] j_entity_arr;
    foreach(id, entity; scene.entities) {
        j_entity_arr ~= Dump(entity);
    }

    JSONValue j;
    j["ui"] = j_ui_arr;
    j["entity"] = j_entity_arr;
    j["script"] = scene.script_name;

    return j;
}

JSONValue Dump(SDL_Color color) {
    JSONValue j;
    j["r"] = color.r;
    j["g"] = color.g;
    j["b"] = color.b;
    return j;
}

JSONValue Dump(GameEntity* e) {
    JSONValue j;
    j["id"] = e.id;
    j["team"] = e.team;
    j["lives"] = e.lives;
    j["x"] = cast(int)e.x;
    j["y"] = cast(int)e.y;
    j["center"] = e.center;
    j["orientation"] = e.orientation;
    

    j["variable_init_script"] = e.variable_init_script_name;
    j["control_script"] = e.control_script_name;;
    j["collission_script"] = e.collission_script_name;
    j["texture"] = e.texture_name;
    return j;
}

void writeTo(string path, JSONValue j ) {
    write(path, j.toString);
}