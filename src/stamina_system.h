#ifndef STAMINA_SYSTEM_H
#define STAMINA_SYSTEM_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class PSTEStamina : public Node {
    GDCLASS(PSTEStamina, Node)
    
private:
    int stamina;
    int max_stamina;
    int hearts;
    int max_hearts;

    static const int BASE_MAX_STAMINA = 10;
    static const int HARD_CAP = 30;
    static const int FIRST_CLEAR_BONUS = 5;

    // tracks which minigame IDs have already been cleared
    // key: minigame_id (String), value: true if cleared
    Dictionary cleared_minigames;

protected:
    static void _bind_methods();

public:
    PSTEStamina();

    // stamina
    void gain_stamina(int amount);
    bool use_stamina(int amount);        // returns false = not enough stamina
    void refill_stamina();

    // hearts
    void lose_heart();
    void gain_heart();

    // floor traversal
    bool try_go_down(int from_floor);   // costs stamina; returns false + blocks if 0
    void go_up();                        // always free

    // minigame reward (call with minigame_id on success)
    void on_minigame_cleared(const String &minigame_id);

    // rest / respawn
    void rest();
    void respawn();

    // getters
    int get_stamina() const;
    int get_max_stamina() const;
    int get_hearts() const;
    int get_max_hearts() const;
    bool is_minigame_cleared(const String &minigame_id) const;
};

} // namespace godot

#endif