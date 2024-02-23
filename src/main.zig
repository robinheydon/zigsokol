const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sgl = sokol.gl;
const sgapp = sokol.app_gfx_glue;
const stm = sokol.time;
const sdtx = sokol.debugtext;

var pass_action : sg.PassAction = .{};
var now : f64 = 0;
var delta_time : f64 = 0;

var frame_time_index : usize = 0;
var frame_times: [8]f64 = undefined;

var go_slow: usize = 0;

export fn init () void
{
    sg.setup (.{
        .context = sgapp.context (),
        .logger = .{ .func = sokol.log.func },
    });

    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.4, .g = 0.4, .b = 0.4, .a = 1 },
    };

    sgl.setup (.{});
    stm.setup ();
    var sdtx_desc: sdtx.Desc = .{};
    sdtx_desc.fonts[0] = sdtx.fontCpc();
    sdtx.setup (sdtx_desc);

    std.debug.print ("{}\n", .{sg.queryBackend()});

    for (0..frame_times.len) |i|
    {
        frame_times[i] = 0;
    }
}

export fn cleanup () void
{
    sdtx.shutdown ();
    stm.setup ();
    sgl.shutdown ();
    sg.shutdown ();
}

fn draw_square (width: f32, height: f32) void
{
    sgl.beginQuads ();
    sgl.v2fC3b (-width/2, -height/2, 192, 192, 64);
    sgl.v2fC3b (width/2, -height/2, 64, 192, 192);
    sgl.v2fC3b (width/2, height/2, 192, 64, 192);
    sgl.v2fC3b (-width/2, height/2, 192, 192, 192);
    sgl.end ();
}

fn draw_frame_times (width: f32, height: f32) void
{
    const bar_height : f32 = @floatCast (height - height * delta_time * 60);

    sgl.viewportf (0, 0, sapp.widthf (), sapp.heightf (), true);
    sgl.defaults ();
    sgl.ortho (0, sapp.widthf (), sapp.heightf (), 0, -1, 1);

    sgl.beginQuads ();
    sgl.c3b (255, 0, 0);
    sgl.v2f (0, bar_height);
    sgl.v2f (width - 1, bar_height);
    sgl.v2f (width - 1, height - 1);
    sgl.v2f (0, height - 1);
    sgl.end ();
}

fn get_now () f64
{
    return stm.sec (stm.now ());
}

export fn frame () void
{
    // delta_time = sapp.frameDuration ();

    now = get_now ();
    frame_times[frame_time_index] = now;
    frame_time_index += 1;
    if (frame_time_index >= frame_times.len)
    {
        frame_time_index = 0;
    }

    delta_time = (now - frame_times[frame_time_index]) / @as (f64, @floatFromInt (frame_times.len - 1));

    // delta_time = now - last_now;
    // last_now = now;

    const fps = 1 / delta_time;

    const width = sapp.widthf ();
    const height = sapp.heightf ();

    sdtx.canvas (width / 4, height / 4);

    sdtx.origin (2.0, 2.0);
    sdtx.home ();
    sdtx.font (0);
    sdtx.color3b (255, 255, 255);
    sdtx.print ("now {d:9.3}\n", .{now});
    sdtx.print ("dt  {d:9.3} ms\n", .{delta_time * 1000});
    sdtx.print ("fps {d:9.0} Hz\n", .{fps});

    sgl.viewportf (0, 0, width, height, true);
    sgl.defaults ();
    sgl.ortho (0, width, height, 0, -1, 1);

    sgl.pushMatrix ();
    sgl.translate (600, 500, 0);
    sgl.rotate (@floatCast (6.28 * now / 4), 0, 0, 1);
    draw_square (800, 800);
    sgl.popMatrix ();

    draw_frame_times (16, height);

    sg.beginDefaultPass (pass_action, sapp.width (), sapp.height ());

    sgl.draw ();
    sdtx.draw ();

    sg.endPass ();

    sg.commit ();

    for (0..go_slow) |_|
    {
        for (0..5_000_000) |i| { _ = i; }
    }
}

export fn event (cev: [*c]const sapp.Event) void
{
    const ev = cev.*;

    switch (ev.type)
    {
        .KEY_DOWN => on_key_down (ev),
        .KEY_UP => on_key_up (ev),
        .CHAR => on_key_char (ev),
        .MOUSE_MOVE => on_mouse_move (ev),
        .MOUSE_DOWN => on_mouse_down (ev),
        .MOUSE_UP => on_mouse_up (ev),
        .MOUSE_LEAVE => on_mouse_leave (ev),
        .MOUSE_ENTER => on_mouse_enter (ev),
        .FOCUSED => on_focused (ev),
        .UNFOCUSED => on_unfocused (ev),
        .ICONIFIED => on_iconified (ev),
        .RESTORED => on_restored (ev),
        .QUIT_REQUESTED => on_quit_requested (ev),
        .RESIZED => on_resized (ev),
        else => {
            std.debug.print ("Event: {}\n", .{ev.type});
        },
    }
}

fn on_key_down (ev: sapp.Event) void
{
    // std.debug.print ("Key: {} Mod: {} Repeat: {}\n", .{ev.key_code, ev.modifiers, ev.key_repeat});

    if (ev.key_code == .ESCAPE and ev.modifiers == 0)
    {
        sapp.requestQuit ();
    }
    else if (ev.key_code == .F11 and ev.modifiers == 0)
    {
        sapp.toggleFullscreen ();
    }
    else if (ev.key_code == .F1 and ev.modifiers == 0)
    {
        if (go_slow < 24)
        {
            go_slow += 1;
        }
    }
    else if (ev.key_code == .F2 and ev.modifiers == 0)
    {
        if (go_slow > 0)
        {
            go_slow -= 1;
        }
    }
}

fn on_key_up (ev: sapp.Event) void
{
    _ = ev;
}

fn on_key_char (ev: sapp.Event) void
{
    _ = ev;
    // std.debug.print ("Key: {x:0>4}\n", .{ev.char_code});
}

fn on_mouse_move (ev: sapp.Event) void
{
    _ = ev;
    if (sapp.mouseLocked ())
    {
        // std.debug.print ("MouseLock: {d},{d}\n", .{ev.mouse_dx, ev.mouse_dy});
    }
    else
    {
        // std.debug.print ("MouseMove: {d},{d}\n", .{ev.mouse_x, ev.mouse_y});
    }
}

fn on_mouse_down (ev: sapp.Event) void
{
    _ = ev;
    // sapp.lockMouse (true);
}

fn on_mouse_up (ev: sapp.Event) void
{
    // sapp.lockMouse (false);
    _ = ev;
}

fn on_mouse_enter (ev: sapp.Event) void
{
    _ = ev;
}

fn on_mouse_leave (ev: sapp.Event) void
{
    _ = ev;
}

fn on_focused (ev: sapp.Event) void
{
    _ = ev;
}

fn on_unfocused (ev: sapp.Event) void
{
    _ = ev;
}

fn on_quit_requested (ev: sapp.Event) void
{
    _ = ev;
}

fn on_iconified (ev: sapp.Event) void
{
    _ = ev;
}

fn on_restored (ev: sapp.Event) void
{
    _ = ev;
}

fn on_resized (ev: sapp.Event) void
{
    _ = ev;

    // std.debug.print ("\nResize {}x{}\n", .{ev.window_width, ev.window_height});
}

pub fn main() !void {
    std.debug.print ("\n", .{});
    sapp.run (.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = event,
        .cleanup_cb = cleanup,
        .width = 1280,
        .height= 720,
        .window_title = "Test",
        .logger = .{ .func = sokol.log.func },
    });
}
