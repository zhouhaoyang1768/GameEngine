import pyd.pyd;
import pyd.embedded;

import std.conv;

import bindbc.sdl;

import resourcemanager;
import ui;
import entity;
import component;
import pythonlib;
import gameapplication;

class SceneNode {
    this () {}
    this(GameEntity* object) {
        this.object = object;
    }
    GameEntity* object = null;
    SceneNode[] next;
}

struct Scene {

    SceneNode root;
    GameEntity*[string] entities;
    UI[] ui;
    string script;
    InterpContext context;

    SDL_Renderer* renderer;
    ResourceManager resources;
    GameApplication game;

    void Update() {
        context.py_stmts(script);
    }

    void addEntity(string id, int team, int lives, double x, double y, bool center, double orientation, string variable_init, string control_script, string collission_script, string texture_name) {
        GameEntity* entity = new GameEntity;

        entity.scene = &this;
        entity.context = new InterpContext();
        addLib(entity.context);
        addSceneLib(&this, entity.context);
        addGameLib(game, entity.context);

        if (variable_init in resources.script) entity.context.py_stmts(resources.script[variable_init]);

        entity.active = true;
        entity.hide = false;
        entity.immune_timer = 0;

        if (id in entities) {
            int nuance = 2;
            while (id ~ to!string(nuance) in entities) {
                nuance++;
            }
            id = id ~ to!string(nuance);
        }

        entity.id = id;
        entity.team = team;
        entity.lives = lives;
        entity.x = x;
        entity.y = y;
        entity.center = center;
        entity.orientation = orientation;

        entity.w = resources.surface[texture_name].w;
        entity.h = resources.surface[texture_name].h;
        


        entity.texture = new ComponentTexture(resources.texture[texture_name], resources.surface[texture_name].w, resources.surface[texture_name].h, entity);
        entity.control = new ComponentScript(entity, resources.script[control_script]);
        if (collission_script in resources.script) entity.collission = new ComponentCollission(entity, resources.script[collission_script]);
        else entity.collission = new ComponentEmpty;

        root.next ~= new SceneNode(entity);
        entities[id] = entity;
    }
}