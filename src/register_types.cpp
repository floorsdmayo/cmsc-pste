#include "register_types.h"
#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include "stamina_system.h"
#include "wirefixer.h"
#include "snake_game.h"
#include "pong_game.h"

using namespace godot;

void initialize_pste_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
    // register other classes here
    ClassDB::register_class<StaminaSystem>();
    ClassDB::register_class<WireFixer>();
    ClassDB::register_class<SnakeLogic>();
    ClassDB::register_class<PongGame>();
}

void uninitialize_pste_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
}

extern "C" {
GDExtensionBool GDE_EXPORT pste_library_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    const GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization
) {
    GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
    init_obj.register_initializer(initialize_pste_module);
    init_obj.register_terminator(uninitialize_pste_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
    return init_obj.init();
}
}