#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class SnakeLogic : public Node {
    GDCLASS(SnakeLogic, Node)

private:
    int grid_width;
    int grid_height;
    int score;
    int phase;
    bool game_over;
    bool won;
    bool ate_last_step;
    float light_radius;
    float base_light_radius;
    float max_light_radius;
    float move_speed;

    Vector2i direction;
    Vector2i next_direction;
    TypedArray<Vector2i> snake_body;
    Vector2i apple_pos;
    TypedArray<Vector2i> walls;
    int apples_since_last_wall;
    TypedArray<Dictionary> statues;

    void spawn_apple();
    void spawn_wall();
    void update_phase();
    void update_statues();
    Vector2i wrap_position(Vector2i pos);
    bool is_wall_at(Vector2i pos);
    bool is_statue_at(Vector2i pos);
    bool is_occupied(Vector2i pos);

public:
    static void _bind_methods();
    SnakeLogic();

    void setup(int width, int height);
    void set_direction(int dx, int dy);
    bool step();
    void clear_walls();
    void clear_statues();
    void trim_to(int length);
    void reset_for_pong();

    int get_score() const;
    int get_phase() const;
    bool is_game_over() const;
    bool is_won() const;
    float get_move_speed() const;
    TypedArray<Vector2i> get_snake_body() const;
    Vector2i get_apple_pos() const;
    TypedArray<Vector2i> get_walls() const;
    TypedArray<Dictionary> get_statues() const;
    float get_light_radius() const;
};

}