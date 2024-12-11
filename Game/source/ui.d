import pyd.pyd;
import pyd.embedded;

import bindbc.sdl;

interface UI {
    void Input();
    void Update();
    void Render(SDL_Renderer* renderer);
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
}

class StaticDisplay : UI {
    SDL_Texture* texture;
    SDL_Rect* location;

    this(SDL_Texture* texture, SDL_Rect *location) {
        this.texture = texture;
        this.location = location;
    }

    ~this() {
        //SDL_DestroyTexture(texture);
    }

    void Input() {

    }
    void Update() {

    }
    void Render(SDL_Renderer* renderer) {
        SDL_RenderCopy(renderer, texture, null, location);
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

    this(SDL_Texture* texture, SDL_Texture* hover_tex, SDL_Rect *location, void delegate(InterpContext) callback) {
        this.texture = texture;
        this.hover_tex = hover_tex;
        this.location = location;
        this.callback = callback;
        this.hover = false;

        context = new InterpContext();


        SDL_Point mouse;
        last = SDL_GetMouseState(&mouse.x,&mouse.y);
    }

    ~this() {
        //SDL_DestroyTexture(texture);
        //SDL_DestroyTexture(hover_tex);
    }

    void Input() {
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

    }
    void Render(SDL_Renderer* renderer) {
       if (hover) SDL_RenderCopy(renderer, hover_tex, null, location);
       else SDL_RenderCopy(renderer, texture, null, location);
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
    void Render(SDL_Renderer* renderer) {
        double angle = (cast(double)max - *current) / max * 360;
        if (angle == 0 || angle == 360) return;
        SDL_RenderCopy(renderer, clock, null, clock_loc);
        SDL_RenderCopyEx(renderer, hand, null, hand_loc, angle, null, SDL_FLIP_NONE);
    }
}