#include "stamina_system.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

StaminaSystem::StaminaSystem() {
    stamina = 10;
    max_stamina = 10;
    hearts = 3;
    max_hearts = 3;
}

void StaminaSystem::_bind_methods() {
    ClassDB::bind_method(D_METHOD("gain_stamina", "amount"), &StaminaSystem::gain_stamina);
    ClassDB::bind_method(D_METHOD("use_stamina", "amount"), &StaminaSystem::use_stamina);
    ClassDB::bind_method(D_METHOD("lose_heart"), &StaminaSystem::lose_heart);
    ClassDB::bind_method(D_METHOD("gain_heart"), &StaminaSystem::gain_heart);
    ClassDB::bind_method(D_METHOD("rest"), &StaminaSystem::rest);
    ClassDB::bind_method(D_METHOD("respawn"), &StaminaSystem::respawn);
    ClassDB::bind_method(D_METHOD("get_stamina"), &StaminaSystem::get_stamina);
    ClassDB::bind_method(D_METHOD("get_max_stamina"), &StaminaSystem::get_max_stamina);
    ClassDB::bind_method(D_METHOD("get_hearts"), &StaminaSystem::get_hearts);
    ClassDB::bind_method(D_METHOD("get_max_hearts"), &StaminaSystem::get_max_hearts);

    ADD_SIGNAL(MethodInfo("stamina_changed", PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("hearts_changed", PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("player_died"));
}

void StaminaSystem::gain_stamina(int amount) {
    stamina = MIN(stamina + amount, max_stamina);
    emit_signal("stamina_changed", stamina);
}

bool StaminaSystem::use_stamina(int amount) {
    if (stamina >= amount) {
        stamina -= amount;
        emit_signal("stamina_changed", stamina);
        if (stamina <= 0) emit_signal("player_died");
        return true;
    }
    return false;
}

void StaminaSystem::lose_heart() {
    hearts = MAX(hearts - 1, 0);
    emit_signal("hearts_changed", hearts);
    if (hearts <= 0) emit_signal("player_died");
}

void StaminaSystem::gain_heart() {
    hearts = MIN(hearts + 1, max_hearts);
    emit_signal("hearts_changed", hearts);
}

void StaminaSystem::rest() {
    stamina = max_stamina;
    hearts = max_hearts;
    emit_signal("stamina_changed", stamina);
    emit_signal("hearts_changed", hearts);
}

void StaminaSystem::respawn() {
    rest();
}

int StaminaSystem::get_stamina() const { return stamina; }
int StaminaSystem::get_max_stamina() const { return max_stamina; }
int StaminaSystem::get_hearts() const { return hearts; }
int StaminaSystem::get_max_hearts() const { return max_hearts; }