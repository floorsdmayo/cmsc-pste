#include "stamina_system.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

PSTEStamina::PSTEStamina() {
    stamina           = BASE_MAX_STAMINA;
    max_stamina       = BASE_MAX_STAMINA;
    hearts            = 3;
    max_hearts        = 3;
    adrenaline_active = false;
}

void PSTEStamina::_bind_methods() {
    ClassDB::bind_method(D_METHOD("gain_stamina", "amount"),             &PSTEStamina::gain_stamina);
    ClassDB::bind_method(D_METHOD("use_stamina", "amount"),              &PSTEStamina::use_stamina);
    ClassDB::bind_method(D_METHOD("refill_stamina"),                     &PSTEStamina::refill_stamina);
    ClassDB::bind_method(D_METHOD("lose_heart"),                         &PSTEStamina::lose_heart);
    ClassDB::bind_method(D_METHOD("gain_heart"),                         &PSTEStamina::gain_heart);
    ClassDB::bind_method(D_METHOD("try_go_down", "from_floor"),          &PSTEStamina::try_go_down);
    ClassDB::bind_method(D_METHOD("go_up"),                              &PSTEStamina::go_up);
    ClassDB::bind_method(D_METHOD("on_minigame_cleared", "minigame_id"), &PSTEStamina::on_minigame_cleared);
    ClassDB::bind_method(D_METHOD("rest"),                               &PSTEStamina::rest);
    ClassDB::bind_method(D_METHOD("respawn"),                            &PSTEStamina::respawn);
    ClassDB::bind_method(D_METHOD("get_stamina"),                        &PSTEStamina::get_stamina);
    ClassDB::bind_method(D_METHOD("get_max_stamina"),                    &PSTEStamina::get_max_stamina);
    ClassDB::bind_method(D_METHOD("get_hearts"),                         &PSTEStamina::get_hearts);
    ClassDB::bind_method(D_METHOD("get_max_hearts"),                     &PSTEStamina::get_max_hearts);
    ClassDB::bind_method(D_METHOD("is_minigame_cleared", "minigame_id"), &PSTEStamina::is_minigame_cleared);
    ClassDB::bind_method(D_METHOD("trigger_adrenaline"),                 &PSTEStamina::trigger_adrenaline);
    ClassDB::bind_method(D_METHOD("is_adrenaline_active"),               &PSTEStamina::is_adrenaline_active);

    ADD_SIGNAL(MethodInfo("stamina_changed",    PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("hearts_changed",     PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("player_exhausted"));
    ADD_SIGNAL(MethodInfo("player_died"));
    ADD_SIGNAL(MethodInfo("adrenaline_triggered"));
}

void PSTEStamina::gain_stamina(int amount) {
    stamina = MIN(stamina + amount, max_stamina);
    emit_signal("stamina_changed", stamina);
}

bool PSTEStamina::use_stamina(int amount) {
    if (stamina >= amount) {
        stamina -= amount;
        emit_signal("stamina_changed", stamina);
        return true;
    }
    return false;
}

void PSTEStamina::refill_stamina() {
    stamina = max_stamina;
    emit_signal("stamina_changed", stamina);
}

void PSTEStamina::lose_heart() {
    hearts = MAX(hearts - 1, 0);
    emit_signal("hearts_changed", hearts);
    if (hearts <= 0) {
        emit_signal("player_died");
    }
}

void PSTEStamina::gain_heart() {
    hearts = MIN(hearts + 1, max_hearts);
    emit_signal("hearts_changed", hearts);
}

bool PSTEStamina::try_go_down(int from_floor) {
    static const int STAIR_COST = 8;
    if (stamina < STAIR_COST) {
        emit_signal("player_exhausted");
        return false;
    }
    return use_stamina(STAIR_COST);
}

void PSTEStamina::go_up() {
    // always free
}

void PSTEStamina::on_minigame_cleared(const String &minigame_id) {
    if (cleared_minigames.has(minigame_id)) {
        return;
    }
    cleared_minigames[minigame_id] = true;
    if (max_stamina < HARD_CAP) {
        max_stamina = MIN(max_stamina + FIRST_CLEAR_BONUS, HARD_CAP);
    }
    stamina = max_stamina;
    emit_signal("stamina_changed", stamina);
}

void PSTEStamina::rest() {
    stamina = max_stamina;
    hearts  = max_hearts;
    emit_signal("stamina_changed", stamina);
    emit_signal("hearts_changed",  hearts);
}

void PSTEStamina::respawn() {
    stamina           = max_stamina;
    hearts            = max_hearts;
    adrenaline_active = false;
    emit_signal("stamina_changed", stamina);
    emit_signal("hearts_changed",  hearts);
}

void PSTEStamina::trigger_adrenaline() {
    adrenaline_active = true;
    stamina = max_stamina + ADRENALINE_SURGE;
    emit_signal("stamina_changed", stamina);
    emit_signal("adrenaline_triggered");
}

bool PSTEStamina::is_adrenaline_active() const {
    return adrenaline_active;
}

int  PSTEStamina::get_stamina()     const { return stamina; }
int  PSTEStamina::get_max_stamina() const { return max_stamina; }
int  PSTEStamina::get_hearts()      const { return hearts; }
int  PSTEStamina::get_max_hearts()  const { return max_hearts; }

bool PSTEStamina::is_minigame_cleared(const String &minigame_id) const {
    return cleared_minigames.has(minigame_id);
}