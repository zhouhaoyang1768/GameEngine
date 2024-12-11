
import scene;
import entity;
import pythonlib;
import resourcemanager;

import bindbc.sdl;

import std.stdio;
import std.string;
import std.typecons;


interface IComponent {
    void Update();
    void Render(SDL_Renderer* renderer);
}

class ComponentEmpty : IComponent {
    void Update() {

    }
    void Render(SDL_Renderer* renderer){

    }
}

class ComponentScript : IComponent {
    import std.conv;
    import pyd.pyd;
    import pyd.embedded;

    this(GameEntity* host, string script) {
        this.host = host;
        this.script = script;
        this.context = host.context;
    }

    void pre() {
        context.x = host.x;
        context.y = host.y;
        context.lives = host.lives;
        context.active = host.active;
        context.orientation = host.orientation;
        context.redirect = "";
    }
    void post() {
        host.x = context.py_eval!double("x");
        host.y = context.py_eval!double("y");
        host.active = context.py_eval!bool("active");
        host.orientation = context.py_eval!double("orientation");
        string redirect = context.py_eval!string("redirect");
        if (redirect != "") host.scene.game.scene = host.scene.game.resources.parseScene(redirect);
    }

    void Update() {
        pre();
        context.py_stmts(script);
        //writeln(host.orientation);
        post();
    }
    void Render(SDL_Renderer* renderer){

    }

    InterpContext context;
    GameEntity* host;
    string script;
}

class ComponentCollission : IComponent {
    this(GameEntity* host, string script) {
        this.host = host;
        this.script = script;
    }

    void Dfs(SceneNode node) {
        if (node is null) return;
        if (node.object != null) {
            GameEntity* other = node.object;

            SDL_Rect host_loc = {cast(int)host.x - host.center * host.w / 2, cast(int)host.y - host.center * host.h / 2, host.w, host.h};
            SDL_Rect other_loc = {cast(int)other.x - other.center * other.w / 2, cast(int)other.y - other.center * other.h / 2, other.w, other.h};

            //writeln(host_loc);

            if (other.active && SDL_HasIntersection(&host_loc, &other_loc) && host.id != other.id) {
                //writeln(host.id, ", ", other.id);;
                host.context.pushDummyFrame();
                copyToContext!("me")(host.context, host);
                copyToContext!("other")(host.context, other);

                host.context.py_stmts(script);

                copyFromContext!("me")(host.context, host);
                host.context.popDummyFrame();
            }
        }
        foreach (next; node.next) {
            Dfs(next);
        }
    }

    void Update() {
        if (host.active) {
            //writeln(host.id);
            Dfs(host.scene.root);
        }
    }
    void Render(SDL_Renderer* renderer){

    }

    GameEntity* host;
    string script;
}

class ComponentTexture : IComponent {

    this(SDL_Texture* texture, int w, int h, GameEntity* host) {
        this.texture = texture;
        this.host = host;

        this.center = host.center;
        this.location = new SDL_Rect;
        this.location.w = w;
        this.location.h = h;
    }

    ~this() {
    }

    void Update() {
        location.x = cast(int)host.x - center * location.w / 2;
        location.y = cast(int)host.y - center * location.h / 2;
    }

    void Render(SDL_Renderer* renderer) {
        //SDL_RenderCopy(renderer, texture, null, location);
        
        SDL_RenderCopyEx(renderer, texture, null, location, (360 - host.orientation + 90), null, SDL_FLIP_NONE);
    }

    bool center;
    GameEntity* host;
    SDL_Rect *location;
    SDL_Texture* texture;
}

struct Frame {
    SDL_Rect* loc;
    int duration;
}

class ComponentAnimatedTexture : IComponent {

    this(SDL_Texture* texture, Frame[] frames, SDL_Rect *location) {
        this.texture = texture;
        this.location = location;
        this.frames = frames;
        timer = 0;
        current_frame = 0;
    }

    ~this() {
    }

    void Update() {
        ++timer;
        if (timer >= frames[current_frame].duration) {
            timer = 0;
            current_frame = cast(int)((current_frame + 1) % frames.length);
        }
    }

    void Render(SDL_Renderer* renderer) {
        SDL_RenderCopy(renderer, texture, frames[current_frame].loc, location);
    }

    SDL_Rect *location;
    SDL_Texture* texture;
    Frame[] frames;
    int timer;
    int current_frame;
}