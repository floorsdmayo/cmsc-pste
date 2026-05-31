#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class PongGame : public Node {
    GDCLASS(PongGame, Node)

private:
    int grid_width;
    int grid_height;
    int player_score;
    int alex_score;
    int max_score;
    bool game_over;
    bool player_won;

    Vector2 ball_pos;
    Vector2 ball_vel;
    float ball_speed;

    // Alex's paddle
    float alex_y;
    float alex_speed;
    float alex_height;

    void reset_ball(bool player_scored);

public:
    static void _bind_methods();
    PongGame();

    void setup(int width, int height);
    bool step(float delta, TypedArray<Vector2i> snake_body);
    
    int get_player_score() const;
    int get_alex_score() const;
    bool is_game_over() const;
    bool is_player_won() const;
    Vector2 get_ball_pos() const;
    float get_alex_y() const;
    float get_alex_height() const;
};

}