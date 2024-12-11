module entity;

import pyd.pyd;
import pyd.embedded;

import component;
import scene;
import editor;
import pythonlib;
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
    double x, y;
    int w, h;
    bool center;
    double orientation;
    int lives;
    string variable_init_script_name;
    string control_script_name;
    string collission_script_name;
    string texture_name;

    bool active;
    int immune_timer;
    bool hide;        

    Scene* scene;

    IComponent texture;
    IComponent control;
    IComponent collission;

    InterpContext context;

    GameEntity* copy(ResourceManager resources) {
        GameEntity* copy = new GameEntity;
        copy.id = id;
        copy.team = team;
        copy.active = active;
        copy.x = x;
        copy.y = y;
        copy.w = w;
        copy.h = h;
        copy.orientation = orientation;
        copy.center = center;
        copy.immune_timer = immune_timer;
        copy.lives = lives;
        copy.hide = hide;

        copy.variable_init_script_name = variable_init_script_name;
        copy.control_script_name = control_script_name;
        copy.collission_script_name = collission_script_name;
        copy.texture_name = texture_name;

        copy.scene = scene;
        copy.texture = new ComponentTexture(resources.texture[texture_name], resources.surface[texture_name].w, resources.surface[texture_name].h, copy);
        copy.control = new ComponentScript(copy, resources.script[control_script_name]);
        if (collission_script_name in resources.script) copy.collission = new ComponentCollission(copy, resources.script[collission_script_name]);
        else copy.collission = new ComponentEmpty;

        copy.context = new InterpContext();
        addLib(copy.context);
        addSceneLib(scene, copy.context);
        addGameLib(scene.editor, copy.context);

        if (variable_init_script_name in resources.script) copy.context.py_stmts(resources.script[variable_init_script_name]);
        return copy;
    }
}
