
import std.string;
import std.typecons;

import pyd.pyd;
import pyd.embedded;
import core.math;
import bindbc.sdl;

import entity;

void addLib(InterpContext context) {
    context.keyPressed = &keyPressed;
    context.mouseLocation = &mouseLocation;
    context.rotate = &rotate;
    context.normalize = &normalize;
    context.leftClick = &leftClick;
    defineEntity(context);
}

void defineEntity(InterpContext context) {
    string defn = 
    "class Entity: \n" ~
    "    id = \"\" \n" ~
    "    team = -1 \n" ~
    "    active = False \n" ~
    "    x = 0 \n" ~
    "    y = 0 \n" ~
    "    orientation = 0.0 \n" ~
    "    immune_timer = 0 \n" ~
    "    lives = 0 \n" ~
    "    hide = False \n";
    context.py_stmts(defn);
}

bool keyPressed(string key) {
    ubyte* state = SDL_GetKeyboardState(null);

    key = key.toLower;
    int code = -1;

    if (key.length == 1) {
        char c = key[0];
        if (c >= 'a' && c <= 'z') {
            code = c - 'a' + 4;
        } else if (c >= '1' && c <= '9') {
            code = c - '1' + 30;
        } else if (c == '0') {
            code = 39;
        }
        
    }
    if (code == -1) return false;
    return state[code] > 0;
}

bool leftClick() {
    int x, y;
    return SDL_BUTTON_LEFT & SDL_GetMouseState(&x, &y);
}

Tuple!(int, "x", int, "y") mouseLocation() {
    Tuple!(int, "x", int, "y") result;
    uint mask = SDL_GetMouseState(&result.x, &result.y);
    return result;
}

Tuple!(double, "x", double, "y") rotate(Tuple!(double, "x", double, "y") vec, double angle) {
    double x = vec.x * cos(angle) - vec.y * sin(angle);
    double y = vec.x * sin(angle) + vec.y * cos(angle);
    vec.x = x;
    vec.y = y;
    return vec;
}

Tuple!(double, "x", double, "y") normalize(Tuple!(double, "x", double, "y") vec) {
    double norm = sqrt(vec.x * vec.x + vec.y * vec.y);
    if (norm == 0) return vec;
    vec.x = vec.x / norm;
    vec.y = vec.y / norm;
    return vec;
}


void copyToContext(string var)(InterpContext context, GameEntity* from) {
    context.py_stmts(var ~ " = Entity()");
    mixin("context." ~ var ~ ".x = from.x;");
    mixin("context." ~ var ~ ".y = from.y;");
    mixin("context." ~ var ~ ".id = from.id;");
    mixin("context." ~ var ~ ".team = from.team;");
    mixin("context." ~ var ~ ".active = from.active;");
    mixin("context." ~ var ~ ".lives = from.lives;");
    mixin("context." ~ var ~ ".immune_timer = from.immune_timer;");
}

void copyFromContext(string var)(InterpContext context, GameEntity* to) {
    mixin("to.x = context.py_eval!double(\"" ~ var ~ ".x\");");
    mixin("to.y = context.py_eval!double(\"" ~ var ~ ".y\");");
    mixin("to.team = context.py_eval!int(\"" ~ var ~ ".team\");");
    mixin("to.active = context.py_eval!bool(\"" ~ var ~ ".active\");");
    mixin("to.lives = context.py_eval!int(\"" ~ var ~ ".lives\");");
    mixin("to.immune_timer = context.py_eval!int(\"" ~ var ~ ".immune_timer\");");
}

/*
alias PyEntity = Tuple!(double, "x", double, "y", string, "id", int, "team", bool, "active", int, "lives", int, "immune_timer");
void toPyEntity(GameEntity* host, PyEntity* py_entity) {
    py_entity.x = host.x;
    py_entity.y = host.y;
    py_entity.id = host.id;
    py_entity.team = host.team;
    py_entity.active = host.active;
    py_entity.lives = host.lives;
    py_entity.immune_timer = host.immune_timer;
}

void copyToGameEntity(PyEntity* py_entity, GameEntity* host) {
    host.x = py_entity.x;
    host.y = py_entity.y;
    host.team = py_entity.team;
    host.active = py_entity.active;
    host.lives = py_entity.lives;
    host.immune_timer = py_entity.immune_timer;
}*/