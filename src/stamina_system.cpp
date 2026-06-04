#include "stamina_system.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

PSTEStamina::PSTEStamina() {
    stamina     = BASE_MAX_STAMINA;
    max_stamina = BASE_MAX_STAMINA;
    hearts      = 3;
    max_hearts  = 3;
}

void PSTEStamina::_bind_methods() {
    // stamina
    ClassDB::bind_method(D_METHOD("gain_stamina", "amount"),        &PSTEStamina::gain_stamina);
    ClassDB::bind_method(D_METHOD("use_stamina", "amount"),         &PSTEStamina::use_stamina);
    ClassDB::bind_method(D_METHOD("refill_stamina"),                &PSTEStamina::refill_stamina);

    // hearts
    ClassDB::bind_method(D_METHOD("lose_heart"),                    &PSTEStamina::lose_heart);
    ClassDB::bind_method(D_METHOD("gain_heart"),                    &PSTEStamina::gain_heart);

    // traversal
    ClassDB::bind_method(D_METHOD("try_go_down", "from_floor"),     &PSTEStamina::try_go_down);
    ClassDB::bind_method(D_METHOD("go_up"),                         &PSTEStamina::go_up);

    // minigame
    ClassDB::bind_method(D_METHOD("on_minigame_cleared", "minigame_id"), &PSTEStamina::on_minigame_cleared);

    // rest / respawn
    ClassDB::bind_method(D_METHOD("rest"),                          &PSTEStamina::rest);
    ClassDB::bind_method(D_METHOD("respawn"),                       &PSTEStamina::respawn);

    // getters
    ClassDB::bind_method(D_METHOD("get_stamina"),                   &PSTEStamina::get_stamina);
    ClassDB::bind_method(D_METHOD("get_max_stamina"),               &PSTEStamina::get_max_stamina);
    ClassDB::bind_method(D_METHOD("get_hearts"),                    &PSTEStamina::get_hearts);
    ClassDB::bind_method(D_METHOD("get_max_hearts"),                &PSTEStamina::get_max_hearts);
    ClassDB::bind_method(D_METHOD("is_minigame_cleared", "minigame_id"), &PSTEStamina::is_minigame_cleared);

    // signals
    ADD_SIGNAL(MethodInfo("stamina_changed",  PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("hearts_changed",   PropertyInfo(Variant::INT, "new_value")));
    ADD_SIGNAL(MethodInfo("player_exhausted"));   // stamina == 0, tried to go down
    ADD_SIGNAL(MethodInfo("player_died"));          // hearts == 0 only
}

// ── stamina ──────────────────────────────────────────────────────────────────

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

// ── hearts ────────────────────────────────────────────────────────────────────

void PSTEStamina::lose_heart() {
    hearts = MAX(hearts - 1, 0);
    emit_signal("hearts_changed", hearts);
    if (hearts <= 0) {
        emit_signal("player_died");
    }
    // stamina == 0 does NOT trigger death anymore
}

void PSTEStamina::gain_heart() {
    hearts = MIN(hearts + 1, max_hearts);
    emit_signal("hearts_changed", hearts);
}

// ── traversal ─────────────────────────────────────────────────────────────────

bool PSTEStamina::try_go_down(int from_floor) {
    static const int STAIR_COST = 6;

    if (stamina <= STAIR_COST) {
        emit_signal("player_exhausted");   // GameManager shows the popup
        return false;
    }
    return use_stamina(STAIR_COST);
    // even if stamina < cost but > 0, we still allow movement
    // (only hard block is stamina == 0)
    bool ok = use_stamina(MIN(STAIR_COST, stamina));
    return ok;
}

void PSTEStamina::go_up() {
    // always free — no stamina cost, no check
}

// ── minigame rewards ──────────────────────────────────────────────────────────

void PSTEStamina::on_minigame_cleared(const String &minigame_id) {
    if (cleared_minigames.has(minigame_id)) {
        // already cleared this one — no reward, no farming
        return;
    }

    cleared_minigames[minigame_id] = true;

    // increase max stamina (hard-capped)
    if (max_stamina < HARD_CAP) {
        max_stamina = MIN(max_stamina + FIRST_CLEAR_BONUS, HARD_CAP);
    }

    // full refill to new max
    stamina = max_stamina;
    emit_signal("stamina_changed", stamina);
}

// ── rest / respawn ────────────────────────────────────────────────────────────

void PSTEStamina::rest() {
    stamina = max_stamina;
    hearts  = max_hearts;
    emit_signal("stamina_changed", stamina);
    emit_signal("hearts_changed",  hearts);
}

void PSTEStamina::respawn() {
    // full restore, floor reset handled by GameManager
    rest();
}

// ── getters ───────────────────────────────────────────────────────────────────

int  PSTEStamina::get_stamina()      const { return stamina; }
int  PSTEStamina::get_max_stamina()  const { return max_stamina; }
int  PSTEStamina::get_hearts()       const { return hearts; }
int  PSTEStamina::get_max_hearts()   const { return max_hearts; }

bool PSTEStamina::is_minigame_cleared(const String &minigame_id) const {
    return cleared_minigames.has(minigame_id);
}