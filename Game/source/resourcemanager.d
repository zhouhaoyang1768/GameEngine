
import pyd.pyd;
import pyd.embedded;

import bindbc.sdl;
import bindbc.sdl.ttf;
import bindbc.sdl.mixer;

import gameapplication;
import component;
import pythonlib;
import entity;
import scene;
import ui;

import std.json;
import std.file;
import std.conv;
import std.stdio;
import std.string;
import std.algorithm;

struct GameAttributes {
    string title;
    int fps = 60;
    int window_width;
    int window_height;

    string opening_scene;
}

class ResourceManager {
    const string asset_path = "assets/";
    const string image_path = asset_path ~ "images/";
    const string audio_path = asset_path ~ "audio/";
    const string scene_path = asset_path ~ "scenes/";
    const string font_path = asset_path ~ "fonts/";
    const string script_path = asset_path ~ "scripts/";

    const string game_attributes_path = asset_path ~ "game_attributes.json";

    SDL_Surface*[string] surface;
    SDL_Texture*[string] texture;
    Mix_Chunk*[string] audio;
    TTF_Font*[int][string] font;
    string[string] script;
    JSONValue[string] scene;
    SDL_Texture*[] text_texture;

    //SDL_Renderer* renderer;
    GameApplication game;

    this(GameApplication game) {
        this.game = game;
    }

    /* ~~~~~  ~~~~~  ~~~~~  loading  ~~~~~  ~~~~~  ~~~~~ */

    GameAttributes* loadGameAttributes() {
        auto file = File(game_attributes_path, "r");
        auto jsonFileContents = file.byLine.joiner("\n");
        auto json = parseJSON(jsonFileContents);
        auto attributes = new GameAttributes;

        attributes.title = json["title"].str;
        attributes.window_width = cast(int)json["window_width"].integer;
        attributes.window_height = cast(int)json["window_height"].integer;
        attributes.opening_scene = json["opening_scene"].str;

        return attributes;
    }

    void setRenderer(SDL_Renderer* renderer) {
        //this.renderer = renderer;
    }

    void loadImages() {
        foreach(string filename; dirEntries(image_path, "*.bmp", SpanMode.shallow)) {
            string key = filename[image_path.length .. $-4];
            writeln(key ~ " : bmp = " ~ filename);
            surface[key] = SDL_LoadBMP(filename.toStringz);
            texture[key] =SDL_CreateTextureFromSurface(game.renderer, surface[key]);
        }
    }

    void loadAudio() {
        foreach(string filename; dirEntries(audio_path, "*.mp3", SpanMode.shallow)) {
            string key = filename[audio_path.length .. $-4];
            writeln(key ~ " : mp3 = " ~ filename);
            audio[key] = Mix_LoadWAV(filename.toStringz);
        }
    }

    void loadScenes() {
        foreach(string filename; dirEntries(scene_path, "*.json", SpanMode.shallow)) {
            string key = filename[scene_path.length .. $-5];
            writeln(key ~ " : scene = " ~ filename);

            auto file = File(filename, "r");
            auto jsonFileContents = file.byLine.joiner("\n");
            scene[key] = parseJSON(jsonFileContents);
        }
    }

    void loadScripts() {
        foreach(string filename; dirEntries(script_path, "*.py", SpanMode.shallow)) {
            string key = filename[script_path.length .. $-3];
            writeln(key ~ " : script = " ~ filename);

            script[key] = readText(filename);
        }
    }

    void loadFont(string name, int size) {
        if (!(name in font)) {
            TTF_Font*[int] temp;
            font[name] = temp;
        }
        if (!(size in font[name])) font[name][size] = TTF_OpenFont((font_path ~ name ~ ".ttf").toStringz, size);
    }


    /* ~~~~~  ~~~~~  ~~~~~  parsing  ~~~~~  ~~~~~  ~~~~~ */

    UI CreateTextUI(string text, string font, int size, SDL_Color color, int x, int y, bool center) {
        SDL_Rect* loc = new SDL_Rect;
        loc.x = x;
        loc.y = y;
        SDL_Texture* tex = CreateText(text, font, size, color, loc);
        if (center) {
            loc.x -= loc.w / 2;
            loc.y -= loc.h / 2;
        }

        UI ui = new StaticDisplay(tex, loc);
        return ui;
    }

    UI CreateTextButton(string text, string font, int size, SDL_Color default_color, SDL_Color hover_color, int x, int y, void delegate(InterpContext) callback, bool center) {
        SDL_Rect* loc = new SDL_Rect;
        loc.x = x;
        loc.y = y;
        SDL_Texture* default_tex = CreateText(text, font, size, default_color, loc);
        SDL_Texture* hover_tex = CreateText(text, font, size, hover_color, loc);
        if (center) {
            loc.x -= loc.w / 2;
            loc.y -= loc.h / 2;
        }

        UI ui = new Button(default_tex, hover_tex, loc, callback);
        return ui;
    }

    UI parseUI(JSONValue ui) {
        string type = ui["type"].str;

        int x = cast(int)ui["x"].integer;
        int y = cast(int)ui["y"].integer;

        bool center = false;
        if ("center" in ui) center = ui["center"].boolean;
        
        if (type == "text_static") {
            string text = ui["text"].str;
            string font = ui["font"].str;
            int size = cast(int)ui["size"].integer;
            SDL_Color color;
            color.r = cast(ubyte)ui["color"]["r"].integer;
            color.g = cast(ubyte)ui["color"]["g"].integer;
            color.b = cast(ubyte)ui["color"]["b"].integer;

            return CreateTextUI(text, font, size, color, x, y, center);
        } else if (type == "button_text") {
            string text = ui["text"].str;
            string font = ui["font"].str;
            int size = cast(int)ui["size"].integer;
            string script = script[ui["script"].str];
            SDL_Color default_color;
            default_color.r = cast(ubyte)ui["default_color"]["r"].integer;
            default_color.g = cast(ubyte)ui["default_color"]["g"].integer;
            default_color.b = cast(ubyte)ui["default_color"]["b"].integer;
            SDL_Color hover_color;
            hover_color.r = cast(ubyte)ui["hover_color"]["r"].integer;
            hover_color.g = cast(ubyte)ui["hover_color"]["g"].integer;
            hover_color.b = cast(ubyte)ui["hover_color"]["b"].integer;

            void callback(InterpContext context) {
                context.redirect = "";
                context.py_stmts(script);
                string redirection = context.py_eval!string("redirect");
                if (redirection != "") game.scene = parseScene(redirection);
            }

            return CreateTextButton(text, font, size, default_color, hover_color, x, y, &callback, center);
        }


        return null;
    }



    void parseEntity(Scene* scene, JSONValue j) {
        string id = j["id"].str;
        int team = cast(int)j["team"].integer;
        int lives = cast(int)j["lives"].integer;
        double x = cast(int)j["x"].integer;
        double y = cast(int)j["y"].integer;
        double orientation = j["orientation"].get!double;

        bool center = false;
        if ("center" in j) center = j["center"].get!bool;
        string variable_init = "";
        if ("variable_init_script" in j) variable_init = j["variable_init_script"].str;
        string control_script_name = j["control_script"].str;
        string collission_script_name = "";
        if ("collission_script" in j) collission_script_name = j["collission_script"].str; 
        string texture_name = j["texture"].str;

        
        //int w = surface[texture_name].w;
        //int h = surface[texture_name].h;

        scene.addEntity(id, team, lives, x, y, center, orientation, variable_init, control_script_name, collission_script_name, texture_name);
/*
        entity.texture = new ComponentTexture(texture[texture_name], surface[texture_name].w, surface[texture_name].h, entity);
        entity.control = new ComponentScript(entity, script[control_script_name]);
        entity.collission = new ComponentCollission(entity);

        return entity;
        */
    }

    Scene* parseScene(string name) {
        JSONValue json = scene[name];
        Scene* scene = new Scene;
        scene.resources = this;
        scene.game = game;
        scene.context = new InterpContext;
        
        addLib(scene.context);
        addSceneLib(scene, scene.context);
        addGameLib(game, scene.context);

        // parse ui
        if ("ui" in json) {
            auto ui_arr = json["ui"].array;
            foreach(ui; ui_arr) {
                scene.ui ~= parseUI(ui);
            }
        }

        // parse entity
        scene.root = new SceneNode;
        if ("entity" in json) {
            auto entity_arr = json["entity"].array;
            foreach(json_entity; entity_arr) {
                parseEntity(scene, json_entity);
            }
        }

        if ("script" in json) {
            string script_name = json["script"].str;
            if (script_name in script)
            scene.script = script[script_name];
        }

        return scene;
    }


    /* ~~~~~  ~~~~~  ~~~~~  misc  ~~~~~  ~~~~~  ~~~~~ */
    void PlayAudio(string name) {
        Mix_PlayChannel(-1, audio[name], 0);
    }

    SDL_Texture* CreateText(string text, string font_name, int size, SDL_Color color, SDL_Rect* location) {
        loadFont(font_name, size);
        TTF_Font *font = font[font_name][size];
        SDL_Surface* surface = TTF_RenderText_Solid(font, text.toStringz, color);
        SDL_Texture* texture = SDL_CreateTextureFromSurface(game.renderer, surface);
        location.w = surface.w;
        location.h = surface.h;
        SDL_FreeSurface(surface);
        text_texture ~= texture;
        return texture;
    }
/*
    ComponentTexture CreateTextureFont(string text, int size, SDL_Color color, int x, int y) {
        import std.string;
        TTF_Font *font = TTF_OpenFont("assets/pixel.ttf", size);
        SDL_Surface* surface = TTF_RenderText_Solid(font, text.toStringz, color);
        SDL_Texture* texture = SDL_CreateTextureFromSurface(game.renderer, surface);
        SDL_Rect* location = new SDL_Rect;
        location.w = surface.w;
        location.h = surface.h;
        location.x = x - surface.w / 2;
        location.y = y - surface.h / 2;
        TTF_CloseFont(font);
        SDL_FreeSurface(surface);
        text_tex ~= texture;

        ComponentTexture CmpTex = new ComponentTexture(texture, location);
        return CmpTex;
    }
*/  

    /* ~~~~~  ~~~~~  ~~~~~  unloading  ~~~~~  ~~~~~  ~~~~~ */

    void FreeText(SDL_Texture* tex) {
        SDL_DestroyTexture(tex);
    }

    void unloadAll() {
        foreach (key, surf; surface) SDL_FreeSurface(surf);
        foreach (key, tex; texture) SDL_DestroyTexture(tex);
        foreach (key, aud; audio) Mix_FreeChunk(aud);
        foreach (key, arr; font) foreach (key2, fon; arr) TTF_CloseFont(fon);
        foreach (tex; text_texture) SDL_DestroyTexture(tex);


        surface.clear();
        texture.clear();
        audio.clear();
        foreach (key, arr; font) arr.clear();
        font.clear();
        script.clear();
        scene.clear();

        text_texture = [];
    }
}

void addSceneLib(Scene* scene, InterpContext context) {
    context.addEntity = &scene.addEntity;
}
    
void addGameLib(GameApplication game, InterpContext context) {
    void redirect(string scene) {
        game.scene = game.resources.parseScene(scene);
    }
    context.redirect = &redirect;
    context.playAudio = &game.resources.PlayAudio;
}