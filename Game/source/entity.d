module entity;

import pyd.pyd;
import pyd.embedded;

import component;
import scene;
import gameapplication;
import resourcemanager;

import bindbc.sdl;

import std.stdio;

struct GameEntity {

    void Input() {
        if (!active) return;
        control.Update();
    }
    void Update() {
        if (!active) return;

        //foreach(sciript; scripots) context.py_stmts(script);
        if (immune_timer > 0) --immune_timer;
        collission.Update();
        texture.Update();
        //writeln(orientation);
    }
    void Render(SDL_Renderer* renderer) {
        if (!active) return;
        texture.Render(renderer);
    }

    string id;
    int team;
    bool active;

    double x, y;
    int w, h;
    bool center;
    double orientation;

    int immune_timer;
    int lives;
    bool hide;

    Scene* scene;

    IComponent texture;
    IComponent control;
    IComponent collission;

    InterpContext context;
}
