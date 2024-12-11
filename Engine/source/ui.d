import pyd.pyd;
import pyd.embedded;

import std.json;

import bindbc.sdl;

import jsondump;
import resourcemanager;

interface UI {
    void Input();
    void Update();
    void Render(SDL_Renderer* renderer);
    JSONValue dump();

    UI copy(ResourceManager);
}

class ScoreBoard : UI {
    import resourcemanager;
    SDL_Texture* texture;
    SDL_Rect* location;

    this(string text, int* score, int x, int y, int size, bool center, ResourceManager* resources) {
        this.text = text;
        this.score = score;
        this.x = x;
        this.y = y;
        this.size = size;
        this.center = center;
        this.resources = resources;
        location = new SDL_Rect;
        SetText();
    }

    ~this() {
        SDL_DestroyTexture(texture);
    }
    JSONValue dump() {
        JSONValue j;
        return j;
    }

    void SetText() {
        import std.conv;
        SDL_Color white = {255, 255, 255};
        SDL_DestroyTexture(texture);
        texture = resources.CreateText(text ~ to!string(*score), "pixel", size, white, location);
        location.x = x;
        location.y = y;
        if (center) {
            location.x -= location.w;
            location.y -= location.h;
        }
        last_score = *score;
    }

    void Input() {

    }
    void Update() {
        if (last_score != *score) SetText();
    }
    void Render(SDL_Renderer* renderer) {
        SDL_RenderCopy(renderer, texture, null, location);
    }
    int last_score;
    string text;
    int* score;
    int x, y;
    int size;
    bool center;
    ResourceManager* resources;

    
    UI copy(ResourceManager){
        return null;
    }
}

class StaticDisplay : UI {
    SDL_Texture* texture;
    SDL_Rect* location;
    
    int x;
    int y;
    string text;
    string font;
    int size;
    SDL_Color color;

    bool* active;

    this(SDL_Texture* texture, SDL_Rect *location, bool* active, int x = 0, int y = 0, string text = "", string font = "", int size = 0, SDL_Color color = SDL_Color(0,0,0)) {
        this.texture = texture;
        this.location = location;

        this.active = active;

        this.x = x;
        this.y = y;
        this.text = text;
        this.font = font;
        this.size = size;
        this.color = color;
    }

    ~this() {
        //SDL_DestroyTexture(texture);
    }

    JSONValue dump() {
        JSONValue j;
        j["type"] = "text_static";
        j["x"] = x;
        j["y"] = y;
        j["text"] = text;
        j["font"] = font;
        j["size"] = size;
        j["color"] = Dump(color);
        return j;
    }

    void Input() {

    }
    void Update() {

    }
    void Render(SDL_Renderer* renderer) {
        if (active && !*active) return;
        SDL_RenderCopy(renderer, texture, null, location);
    }
    
    UI copy(ResourceManager rm) {
        SDL_Rect* loc = new SDL_Rect;
        loc.x = location.x;
        loc.y = location.y;
        loc.w = location.w;
        loc.h = location.h;
        return new StaticDisplay(texture, loc, null);
    }
}

class Button : UI {
    SDL_Texture* texture;
    SDL_Texture* hover_tex;
    SDL_Rect* location;
    bool hover;
    InterpContext context;
    void delegate(InterpContext) callback;

    uint last = 0;

    bool* active;
    
    
    int x;
    int y;
    string text;
    string font;
    int size;
    string script;
    SDL_Color default_color;
    SDL_Color hover_color;

    this(SDL_Texture* texture, SDL_Texture* hover_tex, SDL_Rect *location, void delegate(InterpContext) callback, bool* active,
    int x = 0, int y = 0, string text = "", string font = "", int size = 0, string script = "", SDL_Color default_color = SDL_Color(0,0,0), SDL_Color hover_color = SDL_Color(0,0,0)) {
        this.texture = texture;
        this.hover_tex = hover_tex;
        this.location = location;
        this.callback = callback;
        this.hover = false;
        this.active = active;

        context = new InterpContext();


        SDL_Point mouse;
        last = SDL_GetMouseState(&mouse.x,&mouse.y);

        
        this.x = x;
        this.y = y;
        this.text = text;
        this.font = font;
        this.size = size;
        this.script = script;
        this.default_color = default_color;
        this.hover_color = hover_color;
    }

    ~this() {
        //SDL_DestroyTexture(texture);
        //SDL_DestroyTexture(hover_tex);
    }

    
    JSONValue dump() {
        JSONValue j;
        j["type"] = "button_text";
        j["x"] = x;
        j["y"] = y;
        j["text"] = text;
        j["font"] = font;
        j["size"] = size;
        j["script"] = script;
        j["default_color"] = Dump(default_color);
        j["hover_color"] = Dump(hover_color);
        return j;
    }

    void Input() {
        
        if (active && !*active) return;
        SDL_Point mouse;
        uint mask = SDL_GetMouseState(&mouse.x,&mouse.y);

        if (SDL_PointInRect(&mouse, location)) {
            hover = true;
            if((mask & SDL_BUTTON_LEFT) && mask != last){
                callback(context);
            }
        } else {
            hover = false;
        }
        last = mask;
    }
    void Update() {
        if (active && !*active) return;
    }
    void Render(SDL_Renderer* renderer) {
        
        if (active && !*active) return;
        if (hover) SDL_RenderCopy(renderer, hover_tex, null, location);
        else SDL_RenderCopy(renderer, texture, null, location);
    }

    UI copy(ResourceManager rm) {
        return new Button(texture, hover_tex, location, callback, null);
    }
}

class Timer : UI {
    SDL_Texture* clock;
    SDL_Texture* hand;
    SDL_Rect* clock_loc;
    SDL_Rect* hand_loc;
    SDL_Point* center;
    int max;
    int* current;
    this (SDL_Texture* clock, SDL_Texture* hand, SDL_Rect* clock_loc, SDL_Rect* hand_loc, int max, int* current) {
        this.clock = clock;
        this.hand = hand;
        this.clock_loc = clock_loc;
        this.hand_loc = hand_loc;
        this.max = max;
        this.current = current;
        this.center = new SDL_Point;
        this.center.x = clock_loc.x + clock_loc.w / 2;
        this.center.y = clock_loc.y + clock_loc.h / 2;
    }
    void Input() {

    }
    void Update() {

    }

    

    JSONValue dump() {
        JSONValue j;
        return j;
    }
    void Render(SDL_Renderer* renderer) {
        double angle = (cast(double)max - *current) / max * 360;
        if (angle == 0 || angle == 360) return;
        SDL_RenderCopy(renderer, clock, null, clock_loc);
        SDL_RenderCopyEx(renderer, hand, null, hand_loc, angle, null, SDL_FLIP_NONE);
    }
    UI copy(ResourceManager){
        return null;
    }
}


class Field {
    string text;
}

bool keyPressed(char c, ubyte* state, ubyte* last_state) {

    int code = -1;

    if (c >= 'a' && c <= 'z') {
        code = c - 'a' + 4;
    } else if (c >= '1' && c <= '9') {
        code = c - '1' + 30;
    } else if (c == '0') {
        code = 39;
    } else if (c == '_') {
        code = SDL_SCANCODE_MINUS;
        return state[code] > 0 && state[code] != last_state[code] && (state[SDL_SCANCODE_LSHIFT] || state[SDL_SCANCODE_RSHIFT]);
    }
        
    if (code == -1) return false;
    return state[code] > 0 && state[code] != last_state[code];
}

bool backspace(ubyte* state, ubyte* last_state) {
    const int code = SDL_SCANCODE_BACKSPACE;
    return state[code] > 0 && state[code] != last_state[code];
}

class TextField : UI {
    bool selected = false;
    bool* active;
    Field field;
    ResourceManager mng;
    SDL_Rect *select_location;

    SDL_Texture* texture;
    SDL_Rect* texture_location;


    string text_last;
    uint mouse_last = 0;
    ubyte* keyboard_last;


    ubyte r = 100;
    ubyte g = 100;
    ubyte b = 100;

    this(Field field, ResourceManager mng, int x, int y, bool* active) {
        this.field = field;
        text_last = field.text;
        this.mng = mng;
        this.select_location = new SDL_Rect(x, y, 150, 18);
        this.texture_location = new SDL_Rect(x + 2, y + 2, 0, 0);
        keyboard_last = cast(ubyte*)new ubyte[50];
        this.active = active;
    }
    

    JSONValue dump() {
        JSONValue j;
        return j;
    }

    void mouseInput() {
        SDL_Point mouse;
        uint mask = SDL_GetMouseState(&mouse.x,&mouse.y);
        if ((mask & SDL_BUTTON_LEFT) && mask != mouse_last) {
            selected = (SDL_PointInRect(&mouse, select_location));
        }

        mouse_last = mask;
    }

    void setTexture() {
        if (field.text.length == 0) {
            texture_location.w = 0;
            texture_location.h = 0;
            return;
        }
        texture = mng.CreateText(field.text, "__editor", 0, SDL_Color(0, 0, 0), texture_location);
    }

    void keyboardInput() {
        ubyte* keyboard = SDL_GetKeyboardState(null);
        for (char c = 'a'; c <= 'z'; c++) {
            if (keyPressed(c, keyboard, keyboard_last)) field.text ~= c;
        }
        for (char c = '0'; c <= '9'; c++) {
            if (keyPressed(c, keyboard, keyboard_last)) field.text ~= c;
        }
        if (keyPressed('_', keyboard, keyboard_last)) field.text ~= '_';
        if (backspace(keyboard, keyboard_last) && field.text.length > 0) field.text = field.text[0..$-1];

        keyboard_last[0..50] = keyboard[0..50];

        if (field.text != text_last) {
            setTexture();
            text_last = field.text;
        }
    }

    void Input() {
        if (active && !*active) return;
        mouseInput();
        if (selected) keyboardInput();
    }
    void Update() {
        if (active && !*active) return;
        if (selected) {
            r = 50;
            g = 255;
            b = 50;
        } else {
            r = 100;
            g = 100;
            b = 100;
        }
    }
    void Render(SDL_Renderer* renderer) {
        if (active && !*active) return;
        SDL_SetRenderDrawColor(renderer, r, g, b, 255);
        SDL_RenderFillRect(renderer, select_location);
        
        SDL_RenderCopy(renderer, texture, null, texture_location);
    }
    UI copy(ResourceManager){
        return null;
    }
}