import pyd.pyd;
import pyd.embedded;

import std.conv;
import std.stdio;

import bindbc.sdl;

import resourcemanager;
import ui;
import entity;
import component;
import pythonlib;
import editor;

class SceneNode {
    this () {}
    this(GameEntity* object) {
        this.object = object;
    }
    GameEntity* object = null;
    SceneNode[] next;

    SceneNode copy(ResourceManager resources) {
        SceneNode copy = new SceneNode;
        if (object != null) copy.object = object.copy(resources);
        foreach(n; next) {
            copy.next ~= n.copy(resources);
        }
        return copy;
    }
}

struct Scene {

    string name;
    SceneNode root;
    GameEntity*[string] entities;
    UI[] ui;
    string script_name;
    InterpContext context;

    SDL_Renderer* renderer;
    ResourceManager resources;
    Editor editor;

    void Update() {
        if (script_name in resources.script) context.py_stmts(resources.script[script_name]);
    }

    void addEntity(string id, int team, int lives, double x, double y, bool center, double orientation, string variable_init, string control_script, string collission_script, string texture_name) {
        GameEntity* entity = new GameEntity;
        entity.variable_init_script_name = variable_init;
        entity.control_script_name = control_script;
        entity.collission_script_name = collission_script;
        entity.texture_name = texture_name;

        entity.scene = &this;
        entity.context = new InterpContext();
        addLib(entity.context);
        addSceneLib(&this, entity.context);
        addGameLib(editor, entity.context);

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

    Scene* copy () {
        Scene* copy = new Scene;
        copy.ui = [];
        copy.root = new SceneNode(null);
        copy.name = this.name;
        copy.renderer = renderer;
        copy.resources = resources;
        copy.editor = editor;
        copy.script_name = script_name;
        copy.context = new InterpContext;
        addLib(copy.context);
        addSceneLib(copy, copy.context);
        addGameLib(editor, copy.context);

        foreach (e; entities) {
            copy.addEntity(e.id, e.team, e.lives, e.x, e.y, e.center, e.orientation, e.variable_init_script_name, e.control_script_name, e.collission_script_name, e.texture_name);
        }
        
        foreach(u; ui) {
            copy.ui ~= u.copy(resources);
        }

        
        

        
        return copy;
    }
}