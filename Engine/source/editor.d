import ui;
import scene;
import entity;
import component;
import resourcemanager;

import bindbc.sdl;

import pyd.pyd;
import pyd.embedded;

import std.conv;
import std.stdio;
import std.array;
import std.string;
import std.algorithm.iteration;



class Editor {
    static const extra_w = 200;
    static const extra_h = 200;
    
    SDL_Window* window;
    SDL_Renderer* renderer;

    ResourceManager resources;
    Scene* scene;
    Scene* scopy;

    UI[string] editor_ui;

    GameAttributes* attributes;

    bool editor_running;
    bool scene_running;
    bool can_edit;


    this() {
        loadAll();
        Init();
    }

    ~this() {
        unloadAll();
    }

    void Init() {
        editor_running = true;
        scene_running = false;
        scopy = resources.parseScene(attributes.opening_scene);
        scene = scopy.copy();
        addEditorUI();
    }

    void loadAll() {
        resources = new ResourceManager(this);
        attributes = resources.loadGameAttributes();

        window = SDL_CreateWindow(attributes.title.toStringz, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, attributes.window_width < 1100 ? 1100 : attributes.window_width, attributes.window_height + extra_h, SDL_WINDOW_SHOWN);
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

        resources.setRenderer(renderer); writeln();
        resources.loadImages(); writeln();
        resources.loadAudio(); writeln();
        resources.loadScenes(); writeln();
        resources.loadScripts(); writeln();

        resources.loadEditorResources();
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
                editor_running = false;
            }
        }
    }

    bool Scene_DfsClean(SceneNode node) {
        if (node is null) return false;
        if (node.object != null && node.object.active) return true;
        node.next = filter!(n => Scene_DfsClean(n))(node.next).array;
        return node.next.length > 0;
    }

    void Scene_DfsInput(SceneNode node) {
        if (node is null) return;
        if (node.object != null)  {
            node.object.Input();
        }
        foreach (next; node.next) {
            Scene_DfsInput(next);
        }
    }

    int Scene_DfsUpdate(SceneNode node) {
        int count = 0;
        if (node is null) return 0;
        if (node.object != null) {
            node.object.Update();
            ++count;
        }
        foreach (next; node.next) {
            count += Scene_DfsUpdate(next);
        }
        return count;
    }

    void Scene_DfsRender(SceneNode node){
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
            Scene_DfsRender(next);
        }
    }

    void Scene_Input() {
        Scene_DfsInput(scene.root);
        foreach (ui; scene.ui) {
            ui.Input();
        }
    }

    void Scene_Update() {
        scene.Update();
        int count = Scene_DfsUpdate(scene.root);
        //writeln(count);
        Scene_DfsClean(scene.root);
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

        Scene_DfsRender(scene.root);

        foreach (id, ui; scene.ui) {
            ui.Render(renderer);
        }

        // editor render
        SDL_Rect loc = SDL_Rect(0, attributes.window_height, attributes.window_width < 1100 ? 1100 : attributes.window_width, 200);
        SDL_SetRenderDrawColor(renderer, 50, 50, 50, 255);
        SDL_RenderFillRect(renderer, &loc);

        foreach(ui; editor_ui) ui.Render(renderer); 

        SDL_RenderPresent(renderer);
    }

    void run() {
        import core.exception;
        while (editor_running) {
            uint begin = SDL_GetTicks();
            CheckExit();
            foreach(ui; editor_ui) ui.Input(); 
            foreach(ui; editor_ui) ui.Update(); 
            if(scene_running) {
                try {
                    Scene_Input();
                    Scene_Update();
                } catch (Exception e) {
                    writeln(e.msg);
                } catch (RangeError e) {
                    writeln(e.msg);
                }
            }
            
            Render();
            uint end = SDL_GetTicks();

            int delay = (1000/attributes.fps) - cast(int)(end - begin); if (delay < 0) delay = 0;
            //writeln(delay);
            SDL_Delay(delay);
        }
    }

    void DfsRemove(SceneNode node, string* id) {
        if (node is null) return;
        if (node.object != null && node.object.id == *id) node.object = null;
        foreach(n; node.next) DfsRemove(n, id);
    }

    void addEditorUI() {
        
        bool* can_edit = new bool(true);

        bool* editing_entity = new bool(false);
        bool* editing_ui = new bool(false);
        bool* choosing_scene = new bool(false);

        int winh = attributes.window_height;

        /* ~~~~~  ~~~~~  ~~~~~  ~~~~~ control flow ~~~~~  ~~~~~  ~~~~~  ~~~~~ */

        bool* show_run = new bool(true);
        bool* show_pause = new bool(false);

        void run(InterpContext) {
            scene_running = true;
            *show_run = false;
            *show_pause = true; 

            *can_edit = false;
            
            *editing_entity = false;
            *editing_ui = false;
        }

        void pause (InterpContext ic) {
            scene_running = false;
            *show_run = true;
            *show_pause = false;
        }
        editor_ui["r"] = CreateTextButton("Run", 20, winh + 10, &run, show_run);
        editor_ui["p"] = CreateTextButton("Pause", 20, winh + 10, &pause, show_pause);

        
        void reset (InterpContext ic) {
            scene = scopy.copy();
            scene_running = false;
            *can_edit = true;

            
            *show_run = true;
            *show_pause = false;
        }
        editor_ui["reset"] = CreateTextButton("Reset", 20, winh + 40, &reset, null);

        
        /* ~~~~~  ~~~~~  ~~~~~  ~~~~~ save and reload ~~~~~  ~~~~~  ~~~~~  ~~~~~ */

        void save (InterpContext ic) {
            resources.save(scopy);
        }
        editor_ui["save"] = CreateTextButton("Save", 20, winh + 70, &save, null);

        
        void reload (InterpContext ic) {
            unloadAll();
            loadAll();

            Init();
        }
        editor_ui["reload"] = CreateTextButton("Reload", 20, winh + 100, &reload, null);

        

        void editEntity (InterpContext) {
            *editing_entity = true;
            *editing_ui = false;
            *choosing_scene = false;
        }
        editor_ui["editentity"] = CreateTextButton("Edit Entity", 180, winh + 170, &editEntity, can_edit);

        

        void editUI (InterpContext) {
            *editing_entity = false;
            *editing_ui = true;
            *choosing_scene = false;
        }
        editor_ui["editui"] = CreateTextButton("Edit UI", 320, winh + 170, &editUI, can_edit);
        
        
        void chooseScene (InterpContext) {
            *editing_entity = false;
            *editing_ui = false;
            *choosing_scene = true;
        }
        editor_ui["choosescene"] = CreateTextButton("Choose Scene", 420, winh + 170, &chooseScene, null);
        /* ~~~~~  ~~~~~  ~~~~~  ~~~~~ add entity ~~~~~  ~~~~~  ~~~~~  ~~~~~ */


        Field eid = new Field;
        Field eteam = new Field;
        Field elives = new Field;
        Field ex = new Field;
        Field ey = new Field;
        Field ecenter = new Field;
        Field eorientation = new Field;
        Field einit_var_script = new Field;
        Field econtrol_script = new Field;
        Field ecollission_script = new Field;
        Field etexture_name = new Field;

        void addEntity (InterpContext ic) {
            try {
                scopy.addEntity(eid.text, eteam.text.to!int, elives.text.to!int, ex.text.to!int, ey.text.to!int, ecenter.text.to!bool, eorientation.text.to!int, einit_var_script.text, econtrol_script.text, ecollission_script.text, etexture_name.text);
                scene.addEntity(eid.text, eteam.text.to!int, elives.text.to!int, ex.text.to!int, ey.text.to!int, ecenter.text.to!bool, eorientation.text.to!int, einit_var_script.text, econtrol_script.text, ecollission_script.text, etexture_name.text);
            } catch(Exception e) {
                writeln(e.msg);
            }
        }
        editor_ui["addentity"] = CreateTextButton("Add Entity", 220, winh + 10, &addEntity, editing_entity);

        void removeEntity (InterpContext ic) {
            DfsRemove(scene.root, &eid.text);
            scene.entities.remove(eid.text);
            DfsRemove(scopy.root, &eid.text);
            scopy.entities.remove(eid.text);
        }
        editor_ui["removeEntity"] = CreateTextButton("Remove Entity", 220, winh + 40, &removeEntity, editing_entity);


        editor_ui["eid"] = CreateTextUI("id:", 220, winh + 70, editing_entity);
        editor_ui["eidf"] = new TextField(eid, resources, 220, winh + 100, editing_entity);

        editor_ui["ex"] = CreateTextUI("x:", 400, winh + 10, editing_entity);
        editor_ui["ey"] = CreateTextUI("y:", 400, winh + 40, editing_entity);
        editor_ui["ecenter"] = CreateTextUI("center:", 400, winh + 70, editing_entity);
        editor_ui["eorientation"] = CreateTextUI("orientation:", 400, winh + 100, editing_entity);
        editor_ui["elives"] = CreateTextUI("lives:", 400, winh + 130, editing_entity);

        editor_ui["exf"] = new TextField(ex, resources, 520, winh + 10, editing_entity); 
        editor_ui["eyf"] = new TextField(ey, resources, 520, winh + 40, editing_entity); 
        editor_ui["ecenterf"] = new TextField(ecenter, resources, 520, winh + 70, editing_entity); 
        editor_ui["eorientationf"] = new TextField(eorientation, resources, 520, winh + 100, editing_entity); 
        editor_ui["elivesf"] = new TextField(elives, resources, 520, winh + 130, editing_entity); 


        
        editor_ui["eteam"] = CreateTextUI("team:", 680, winh + 10, editing_entity);
        editor_ui["einit_var_script"] = CreateTextUI("initialize:", 680, winh + 40, editing_entity);
        editor_ui["econtrol_script"] = CreateTextUI("control:", 680, winh + 70, editing_entity);
        editor_ui["ecollission_script"] = CreateTextUI("collission:", 680, winh + 100, editing_entity);
        editor_ui["etexture_name"] = CreateTextUI("texture:", 680, winh + 130, editing_entity);

        editor_ui["eteamf"] = new TextField(eteam, resources, 780, winh + 10, editing_entity);
        editor_ui["einit_var_scriptf"] = new TextField(einit_var_script, resources, 780, winh + 40, editing_entity); 
        editor_ui["econtrol_scriptf"] = new TextField(econtrol_script, resources, 780, winh + 70, editing_entity); 
        editor_ui["ecollission_scriptf"] = new TextField(ecollission_script, resources, 780, winh + 100, editing_entity); 
        editor_ui["etexture_namef"] = new TextField(etexture_name, resources, 780, winh + 130, editing_entity);  

        
        /* ~~~~~  ~~~~~  ~~~~~  ~~~~~ add ui ~~~~~  ~~~~~  ~~~~~  ~~~~~ */

        
        Field utype = new Field;
        Field ux = new Field;
        Field uy = new Field;
        Field ucenter = new Field;
        
        Field utext = new Field;
        Field ufont = new Field;
        Field usize = new Field;
        Field uscript = new Field;

        Field udr = new Field;
        Field udg = new Field;
        Field udb = new Field; 
        Field uhr = new Field;
        Field uhg = new Field;
        Field uhb = new Field;

        void addUI (InterpContext ic) {
            string type = utype.text;
            try {
                writeln("1");
                if (type == "button"){
                    void callback(InterpContext context) {
                        context.redirect = "";
                        context.py_stmts(resources.script[uscript.text]);
                        string redirection = context.py_eval!string("redirect");
                        if (redirection != "") scene = resources.parseScene(redirection);
                    }
                    scene.ui ~= resources.CreateTextButton(utext.text, ufont.text, usize.text.to!int, SDL_Color(udr.text.to!ubyte,udg.text.to!ubyte,udb.text.to!ubyte),
                    SDL_Color(uhr.text.to!ubyte,uhg.text.to!ubyte,uhb.text.to!ubyte), ux.text.to!int, uy.text.to!int, &callback, ucenter.text.to!bool, uscript.text);
                    
                    scopy.ui ~= resources.CreateTextButton(utext.text, ufont.text, usize.text.to!int, SDL_Color(udr.text.to!ubyte,udg.text.to!ubyte,udb.text.to!ubyte),
                    SDL_Color(uhr.text.to!ubyte,uhg.text.to!ubyte,uhb.text.to!ubyte), ux.text.to!int, uy.text.to!int, &callback, ucenter.text.to!bool, uscript.text);
                } else if (type == "text") {
                    scene.ui ~= resources.CreateTextUI(utext.text, ufont.text, usize.text.to!int, SDL_Color(udr.text.to!ubyte,udg.text.to!ubyte,udb.text.to!ubyte),
                    ux.text.to!int, uy.text.to!int, ucenter.text.to!bool);
                    writeln("2");
                    scopy.ui ~= resources.CreateTextUI(utext.text, ufont.text, usize.text.to!int, SDL_Color(udr.text.to!ubyte,udg.text.to!ubyte,udb.text.to!ubyte),
                    ux.text.to!int, uy.text.to!int, ucenter.text.to!bool);
                }
            } catch (Exception e) {
                writeln(e.msg);
            }
            writeln("2");
        }
        editor_ui["addui"] = CreateTextButton("Add UI", 220, winh + 10, &addUI, editing_ui);        
        void removeUI (InterpContext ic) {
            writeln("remove ui");
        }
        editor_ui["removeUI"] = CreateTextButton("Remove UI", 220, winh + 40, &removeUI, editing_ui);

        
        editor_ui["utype"] = CreateTextUI("type:", 400, winh + 10, editing_ui);
        editor_ui["ux"] = CreateTextUI("x:", 400, winh + 40, editing_ui);
        editor_ui["uy"] = CreateTextUI("y:", 400, winh + 70, editing_ui);
        editor_ui["ucenter"] = CreateTextUI("center:", 400, winh + 100, editing_ui);

        editor_ui["utypef"] = new TextField(utype, resources, 480, winh + 10, editing_ui); 
        editor_ui["uxf"] = new TextField(ux, resources, 480, winh + 40, editing_ui); 
        editor_ui["uyf"] = new TextField(uy, resources, 480, winh + 70, editing_ui); 
        editor_ui["ucenterf"] = new TextField(ucenter, resources, 480, winh + 100, editing_ui); 

        

        editor_ui["utext"] = CreateTextUI("text:", 650, winh + 10, editing_ui);
        editor_ui["ufont"] = CreateTextUI("font:", 650, winh + 40, editing_ui);
        editor_ui["usize"] = CreateTextUI("size:", 650, winh + 70, editing_ui);
        editor_ui["uscripot"] = CreateTextUI("script:", 650, winh + 100, editing_ui);

        editor_ui["utextf"] = new TextField(utext, resources, 740, winh + 10, editing_ui); 
        editor_ui["ufontf"] = new TextField(ufont, resources, 740, winh + 40, editing_ui); 
        editor_ui["usizef"] = new TextField(usize, resources, 740, winh + 70, editing_ui); 
        editor_ui["uscriptf"] = new TextField(uscript, resources, 740, winh + 100, editing_ui); 

        
        editor_ui["udr"] = CreateTextUI("r:", 910, winh + 10, editing_ui);
        editor_ui["udg"] = CreateTextUI("g:", 910, winh + 40, editing_ui);
        editor_ui["udb"] = CreateTextUI("b:", 910, winh + 70, editing_ui);
        editor_ui["uhr"] = CreateTextUI("r2:", 910, winh + 100, editing_ui);
        editor_ui["uhg"] = CreateTextUI("g2:", 910, winh + 130, editing_ui);
        editor_ui["uhb"] = CreateTextUI("b2:", 910, winh + 160, editing_ui);

        
        editor_ui["udrf"] = new TextField(udr, resources, 940, winh + 10, editing_ui); 
        editor_ui["udgf"] = new TextField(udg, resources, 940, winh + 40, editing_ui); 
        editor_ui["udbf"] = new TextField(udb, resources, 940, winh + 70, editing_ui); 
        editor_ui["uhrf"] = new TextField(uhr, resources, 940, winh + 100, editing_ui); 
        editor_ui["uhgf"] = new TextField(uhg, resources, 940, winh + 130, editing_ui); 
        editor_ui["uhbf"] = new TextField(uhb, resources, 940, winh + 160, editing_ui); 

        
        /* ~~~~~  ~~~~~  ~~~~~  ~~~~~ add scene ~~~~~  ~~~~~  ~~~~~  ~~~~~ */

        Field sname = new Field;

        void addScene(InterpContext) {
            if (sname.text in resources.scene) {
                scene = resources.parseScene(sname.text);
                scopy = resources.parseScene(sname.text);
            } else if (sname.text == scene.name) {
                scene = scopy.copy();
            } else {
                scopy = new Scene();
                scopy.name = sname.text;
                scopy.editor = this;

                scene = scopy.copy();
            }
        }
        
        editor_ui["addscene"] = CreateTextButton("Add/Switch Scene", 220, winh + 10, &addScene, choosing_scene);        

        void removeScene (InterpContext ic) {
            if (sname.text in resources.scene) resources.scene.remove(sname.text);
        }
        editor_ui["removescene"] = CreateTextButton("Remove Scene", 220, winh + 40, &removeScene, choosing_scene);

        
        editor_ui["sname"] = CreateTextUI("name:", 400, winh + 10, choosing_scene);
        editor_ui["snamef"] = new TextField(sname, resources, 400, winh + 40, choosing_scene); 
        
    }

    UI CreateTextButton(string text, int x, int y, void delegate(InterpContext) callback, bool* active) {
        SDL_Rect* loc = new SDL_Rect;
        loc.x = x;
        loc.y = y;

        SDL_Color default_color = {255, 255, 255};
        SDL_Color hover_color = {255, 0, 0};
        string font = "__editor";
        int size = 0;

        SDL_Texture* default_tex = resources.CreateText(text, font, size, default_color, loc);
        SDL_Texture* hover_tex = resources.CreateText(text, font, size, hover_color, loc);

        UI ui = new Button(default_tex, hover_tex, loc, callback, active);
        return ui;
    }

    UI CreateTextUI(string text, int x, int y, bool* active) {
        string font = "__editor";
        int size = 0;
        SDL_Color color = SDL_Color(255, 50, 50);
        SDL_Rect* loc = new SDL_Rect;
        loc.x = x;
        loc.y = y;
        SDL_Texture* tex = resources.CreateText(text, font, size, color, loc);

        UI ui = new StaticDisplay(tex, loc, active, loc.x, loc.y, text, font, size, color);
        return ui;
    }


}