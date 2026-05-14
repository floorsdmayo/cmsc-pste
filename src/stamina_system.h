#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class StaminaSystem : public Node {
    GDCLASS(StaminaSystem, Node)

private:
    int stamina;
    int max_stamina;
    int hearts;
    int max_hearts;

public:
    static void _bind_methods();

    StaminaSystem();

    void gain_stamina(int amount);
    bool use_stamina(int amount);
    void lose_heart();
    void gain_heart();
    void rest();
    void respawn();

    int get_stamina() const;
    int get_max_stamina() const;
    int get_hearts() const;
    int get_max_hearts() const;
};

}