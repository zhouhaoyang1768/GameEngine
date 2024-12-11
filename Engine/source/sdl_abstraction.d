// Load the SDL2 library
module sdl_abstraction;

import std.stdio;
import std.string;

import bindbc.sdl;
import bindbc.sdl.ttf; 
import loader = bindbc.loader.sharedlib;
// global variable for sdl;
const SDLSupport ret;
const SDLTTFSupport ttf_ret;
const SDLMixerSupport mixer_ret;
/// At the module level we perform any initialization before our program
/// executes. Effectively, what I want to do here is make sure that the SDL
/// library successfully initializes.
shared static this(){
		// Load the SDL libraries from bindbc-sdl
		// on the appropriate operating system
    version(Windows){
    		writeln("Searching for SDL on Windows");
				ret = loadSDL("SDL2.dll");
		}
  	version(OSX){
      	writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version(linux){ 
      	writeln("Searching for SDL on Linux");
				ret = loadSDL();
		}

		// Error if SDL cannot be loaded
    if(ret != sdlSupport){
        writeln("error loading SDL library");    
        foreach( info; loader.errors){
            writeln(info.error,':', info.message);
        }
    }
    if(ret == SDLSupport.noLibrary){
        writeln("error no library found");
    }
    if(ret == SDLSupport.badLibrary){
        writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
    }

    version(Windows){
    		writeln("Searching for SDL TTF on Windows");
            ttf_ret = loadSDLTTF("SDL2_ttf.dll");
		}
  	version(OSX){
      	writeln("Searching for SDL TTF on Mac");
        ttf_ret = loadSDLTTF();
    }
    version(linux){ 
      	writeln("Searching for SDL TTF on Linux");
				ttf_ret = loadSDLTTF();
	}

    if(ttf_ret != sdlTTFSupport) {
        writeln("Error loading true type font");
    }

    version(Windows){
        writeln("Searching for SDL Mixer on Windows");
        mixer_ret = loadSDLMixer("SDL2_mixer.dll");
    }
  	version(OSX){
      	writeln("Searching for SDL Mixer on Mac");
        mixer_ret = loadSDLMixer();
    }
    version(linux){ 
      	writeln("Searching for SDL Mixer on Linux");
		mixer_ret = loadSDLMixer();
	}

    if(mixer_ret != sdlMixerSupport) {
        writeln("Error loading audio");
    }

    if(TTF_Init() != 0) {
        writeln("TTF_Init: ", fromStringz(SDL_GetError()));
    }
    // Initialize SDL
    if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }

    if( Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 2048 ) < 0 ) {
        writeln( "SDL_mixer could not initialize! SDL_mixer Error: ", Mix_GetError() );
    }
}

/// At the module level, when we terminate, we make sure to 
/// terminate SDL, which is initialized at the start of the application.
shared static ~this(){
    // Quit the SDL Application 
    SDL_Quit();
		writeln("Ending application--good bye!");
}
