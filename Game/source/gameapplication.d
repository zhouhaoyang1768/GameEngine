module gameapplication;

import ui;
import scene;
import entity;
import component;
import resourcemanager;

import bindbc.sdl;

import std.stdio;
import std.array;
import std.string;
import std.algorithm.iteration;


class GameApplication {
    
    SDL_Window* window;
    SDL_Renderer* renderer;

    ResourceManager resources;
    Scene* scene;

    GameAttributes* attributes;

    bool running;
    

    this() {
        loadAll();
    }

    ~this() {
        unloadAll();
    }

    void loadAll() {
        resources = new ResourceManager(this);
        attributes = resources.loadGameAttributes();

        window = SDL_CreateWindow(attributes.title.toStringz, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, attributes.window_width, attributes.window_height, SDL_WINDOW_SHOWN);
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

        resources.setRenderer(renderer); writeln();
        resources.loadImages(); writeln();
        resources.loadAudio(); writeln();
        resources.loadScenes(); writeln();
        resources.loadScripts(); writeln();

        running = true;
        scene = resources.parseScene(attributes.opening_scene);
    }

    void unloadAll() {
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        resources.unloadAll();
    }

    void CheckExit() {
        SDL_Event event;
        while(SDL_PollEvent(&event)){
            if(event.type == SDL_QUIT){
                running= false;
            }
        }
    }

    bool DfsClean(SceneNode node) {
        if (node is null) return false;
        if (node.object != null && node.object.active) return true;
        node.next = filter!(n => DfsClean(n))(node.next).array;
        return node.next.length > 0;
    }

    void DfsInput(SceneNode node) {
        if (node is null) return;
        if (node.object != null)  {
            node.object.Input();
        }
        foreach (next; node.next) {
            DfsInput(next);
        }
    }

    int DfsUpdate(SceneNode node) {
        int count = 0;
        if (node is null) return 0;
        if (node.object != null) {
            node.object.Update();
            ++count;
        }
        foreach (next; node.next) {
            count += DfsUpdate(next);
        }
        return count;
    }

    void DfsRender(SceneNode node){
        if (node is null) return;
        if (node.object != null) {
            SDL_ClearError();
            node.object.Render(renderer);
            import std.conv;
            string error = to!string(SDL_GetError());
            if (error.length) {
                writeln("Id: ", node.object.id);
                writeln("Error: ", error);
            }
        }
        foreach (next; node.next) {
            DfsRender(next);
        }
    }

    void Input() {
        DfsInput(scene.root);
        foreach (ui; scene.ui) {
            ui.Input();
        }
    }

    void Update() {
        scene.Update();
        int count = DfsUpdate(scene.root);
        //writeln(count);
        DfsClean(scene.root);
        foreach(id, entity; scene.entities) {
            if (!entity.active) scene.entities.remove(id);
        }
        foreach (ui; scene.ui) {
            ui.Update();
        }
    }

    void Render() {
        SDL_SetRenderDrawColor(renderer,0,0,0,SDL_ALPHA_OPAQUE);
        SDL_RenderClear(renderer);

        DfsRender(scene.root);

        foreach (ui; scene.ui) {
            ui.Render(renderer);
        }
        SDL_RenderPresent(renderer);
    }

    void run() {
        while (running) {
            uint begin = SDL_GetTicks();
            CheckExit();
            Input();
            Update();
            Render();
            uint end = SDL_GetTicks();

            int delay = (1000/attributes.fps) - cast(int)(end - begin); if (delay < 0) delay = 0;
            //writeln(delay);
            SDL_Delay(delay);
        }
    }
}