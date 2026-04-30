using Budgie;
using Gtk;
using GLib;

public class WPVolumeApplet : Budgie.Applet {
    private Label label;
    private int volume = 30;
    private bool muted = false;

    private Gtk.Window slider_window;
    private Gtk.DrawingArea slider_area;

    public WPVolumeApplet(string uuid) {
        Object();
        var event_box = new Gtk.EventBox();
        event_box.add_events(Gdk.EventMask.SCROLL_MASK | Gdk.EventMask.BUTTON_PRESS_MASK);

        label = new Gtk.Label("");
        label.set_markup("<span size='9000'>🔊</span>");

        event_box.add(label);
        this.add(event_box);

        setup_slider_window();
        this.show_all();

        event_box.button_press_event.connect(on_click);
        event_box.scroll_event.connect(on_scroll);
        update_from_system();
    }

    private void setup_slider_window() {
        slider_window = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
        
        var screen = slider_window.get_screen();
        var visual = screen.get_rgba_visual();
        if (visual != null) slider_window.set_visual(visual);

        GtkLayerShell.init_for_window(slider_window);
        GtkLayerShell.set_layer(slider_window, GtkLayerShell.Layer.OVERLAY);
        
        // Kotwice niezbędne do poprawnego działania marginesów w Labwc
        GtkLayerShell.set_anchor(slider_window, GtkLayerShell.Edge.TOP, true);
        GtkLayerShell.set_anchor(slider_window, GtkLayerShell.Edge.LEFT, true);
        
        // Tryb ON_DEMAND pozwala na zamykanie okna przy kliknięciu poza nim
        GtkLayerShell.set_keyboard_mode(slider_window, GtkLayerShell.KeyboardMode.ON_DEMAND);

        slider_window.set_decorated(false);
        slider_window.set_resizable(false);
        slider_window.set_default_size(50, 250);

        // Zamykanie przy utracie fokusu (kliknięcie w pulpit/inne okno)
        slider_window.focus_out_event.connect(() => {
            slider_window.hide();
            return false;
        });

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.set_margin_top(10);
        box.set_margin_bottom(10);
        box.set_margin_start(10);
        box.set_margin_end(10);

        slider_area = new Gtk.DrawingArea();
        slider_area.set_size_request(30, 230);
        slider_area.add_events(Gdk.EventMask.BUTTON_PRESS_MASK | 
                             Gdk.EventMask.BUTTON_MOTION_MASK | 
                             Gdk.EventMask.SCROLL_MASK |
                             Gdk.EventMask.SMOOTH_SCROLL_MASK);

        slider_area.draw.connect(on_draw);
        slider_area.button_press_event.connect(on_slider_click);
        slider_area.motion_notify_event.connect(on_slider_motion);
        slider_area.scroll_event.connect(on_scroll);

        box.pack_start(slider_area, true, true, 0);
        slider_window.add(box);
        slider_window.hide();
    }

    private bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
        Gtk.Allocation alloc;
        widget.get_allocation(out alloc);

        // Czyścimy tło okna
        cr.set_source_rgba(0, 0, 0, 0);
        cr.set_operator(Cairo.Operator.SOURCE);
        cr.paint();
        cr.set_operator(Cairo.Operator.OVER);

        // Tło paska
        cr.set_source_rgba(0.05, 0.05, 0.05, 0.9);
        cr.rectangle(0, 0, alloc.width, alloc.height);
        cr.fill();

        // Wypełnienie głośności
        double fill_height = (alloc.height * (volume / 100.0));
        cr.set_source_rgba(0.0, 0.8, 0.8, 1.0);
        cr.rectangle(0, alloc.height - fill_height, alloc.width, fill_height);
        cr.fill();

        // Rysowanie tekstu % z obramowaniem dla czytelności
        cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
        cr.set_font_size(13);
        string text = @"$volume%";
        Cairo.TextExtents extents;
        cr.text_extents(text, out extents);
        
        double x = (alloc.width - extents.width) / 2;
        double y = alloc.height - 15;

        // Czarny "cień/obrys" (rysujemy tekst 8 razy dookoła o 1px)
        cr.set_source_rgba(0, 0, 0, 0.8);
        for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
                cr.move_to(x + i, y + j);
                cr.show_text(text);
            }
        }

        // Główny biały tekst
        cr.set_source_rgba(1, 1, 1, 1);
        cr.move_to(x, y);
        cr.show_text(text);

        return false;
    }

    private void set_volume(int v) {
        volume = v.clamp(0, 100);
        try {
            Process.spawn_command_line_async(@"wpctl set-volume @DEFAULT_AUDIO_SINK@ $volume%");
        } catch (Error e) {}
        update_label();
        // Wymuszenie odświeżenia grafiki na pasku
        if (slider_area != null) slider_area.queue_draw();
    }

    private void position_slider_under_icon() {
        int root_x, root_y;
        this.get_window().get_origin(out root_x, out root_y);
        Gtk.Allocation alloc;
        this.get_allocation(out alloc);
        
        int target_x = root_x + (alloc.width / 2) - 25;
        int target_y = root_y + alloc.height + 5;

        GtkLayerShell.set_margin(slider_window, GtkLayerShell.Edge.LEFT, target_x);
        GtkLayerShell.set_margin(slider_window, GtkLayerShell.Edge.TOP, target_y);
    }

    private bool on_click(Gdk.EventButton event) {
        if (event.button == 1) {
            if (slider_window.get_visible()) {
                slider_window.hide();
            } else {
                update_from_system();
                position_slider_under_icon();
                slider_window.show_all();
                slider_window.present();
            }
            return true;
        }
        if (event.button == 2) { toggle_mute(); return true; }
        if (event.button == 3) { show_menu(event); return true; }
        return false;
    }

    private bool on_scroll(Gdk.EventScroll event) {
        double delta_x, delta_y;
        if (event.get_scroll_deltas(out delta_x, out delta_y)) {
            if (delta_y > 0) set_volume(volume - 2);
            else if (delta_y < 0) set_volume(volume + 2);
        } else {
            if (event.direction == Gdk.ScrollDirection.UP) set_volume(volume + 2);
            else if (event.direction == Gdk.ScrollDirection.DOWN) set_volume(volume - 2);
        }
        return true;
    }

    private void update_label() {
        string icon = muted ? "🔇" : "🔊";
        label.set_markup(@"<span size='9000'>$icon</span>");
        this.set_tooltip_text(@"Głośność: $volume%%");
    }

    private void update_from_system() {
        string[] args = {"wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"};
        try {
            var proc = new Subprocess.newv(args, SubprocessFlags.STDOUT_PIPE);
            proc.communicate_utf8_async.begin(null, null, (o, res) => {
                try {
                    string stdout;
                    proc.communicate_utf8_async.end(res, out stdout, null);
                    muted = stdout.contains("MUTED");
                    var parts = stdout.split(" ");
                    if (parts.length >= 2) {
                        volume = (int)(double.parse(parts[1]) * 100).clamp(0, 100);
                    }
                    update_label();
                    if (slider_area != null) slider_area.queue_draw();
                } catch (Error e) {}
            });
        } catch (Error e) {}
    }

    private bool on_slider_click(Gtk.Widget widget, Gdk.EventButton event) {
        return update_slider_from_click(event.y);
    }

    private bool on_slider_motion(Gtk.Widget widget, Gdk.EventMotion event) {
        if ((event.state & Gdk.ModifierType.BUTTON1_MASK) != 0) {
            return update_slider_from_click(event.y);
        }
        return false;
    }

    private bool update_slider_from_click(double y) {
        Gtk.Allocation alloc;
        slider_area.get_allocation(out alloc);
        volume = (int)((alloc.height - y) / alloc.height * 100.0).clamp(0, 100);
        set_volume(volume);
        return true;
    }

    private void toggle_mute() {
        try {
            Process.spawn_command_line_async("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
        } catch (Error e) {}
        Timeout.add(50, () => { update_from_system(); return false; });
    }

    private void show_menu(Gdk.EventButton event) {
        var menu = new Gtk.Menu();
        var item = new Gtk.MenuItem.with_label("Ustawienia (Wiremix)");
        item.activate.connect(() => {
            try { Process.spawn_command_line_async("tilix --maximize -e wiremix"); } catch (Error e) {}
        });
        menu.append(item);
        menu.show_all();
        menu.popup_at_pointer(event);
    }
}

public class Plugin : GLib.Object, Budgie.Plugin {
    public Budgie.Applet get_panel_widget(string uuid) { return new WPVolumeApplet(uuid); }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(Plugin));
}
