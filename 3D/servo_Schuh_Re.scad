//Par. Servo Arm
color( "red", 1.0 ){
translate([-16,-93,-3.15])
linear_extrude(height = 3)
import ("SchuhgelenkRe.svg");
}
arm_length = 7;

arm_count = 0; // [1,2,3,4,5,6,7,8]

//  Clear between arm head and servo head (PLA: 0.3, ABS 0.2)
SERVO_HEAD_CLEAR = 0.3; // [0.2,0.3,0.4,0.5]

$fn = 100 / 1;

/**
 *  Head / Tooth parameters
 *  Futaba 3F Standard Spline
 *  http://www.servocity.com/html/futaba_servo_splines.html
 *
 *  First array (head related) :
 *  0. Head external diameter
 *  1. Head heigth
 *  2. Head thickness
 *  3. Head screw diameter
 *
 *  Second array (tooth related) :
 *  0. Tooth count
 *  1. Tooth height
 *  2. Tooth length
 *  3. Tooth width
 */
FUTABA_3F_SPLINE = [
    [4.7, 3.5, 1.1, 2.5],
    [25, 0.4, 0.6, 0.0]
];

module servo_futaba_3f(length, count) {
    servo_arm(FUTABA_3F_SPLINE, [length, count]);
}

/**
 *  If you want to support a new servo, juste add a new spline definition array
 *  and a module named like servo_XXX_YYY where XXX is servo brand and YYY is the
 *  connection type (3f) or the servo type (s3003)
 */

module servo_standard(length, count) {
    servo_futaba_3f(length, count);
}

/**
 *  Tooth
 *
 *    |<-w->|
 *    |_____|___
 *    /     \  ^h
 *  _/       \_v
 *   |<--l-->|
 *
 *  - tooth length (l)
 *  - tooth width (w)
 *  - tooth height (h)
 *  - height
 *
 */
module servo_head_tooth(length, width, height, head_height) {
    linear_extrude(height = head_height) {
        polygon([[-length / 2, 0], [-width / 2, height], [width / 2, height], [length / 2,0]]);
    }
}

/**
 *  Servo head
 */
module servo_head(params, clear = SERVO_HEAD_CLEAR) {

    head = params[0];
    tooth = params[1];

    head_diameter = head[0];
    head_heigth = head[1];

    tooth_count = tooth[0];
    tooth_height = tooth[1];
    tooth_length = tooth[2];
    tooth_width = tooth[3];

    % cylinder(r = head_diameter / 2, h = head_heigth + 1);

    cylinder(r = head_diameter / 2 - tooth_height + 0.03 + clear, h = head_heigth);

    for (i = [0 : tooth_count]) {
        rotate([0, 0, i * (360 / tooth_count)]) {
            translate([0, head_diameter / 2 - tooth_height + clear, 0]) {
                servo_head_tooth(tooth_length, tooth_width, tooth_height, head_heigth);
            }
        }
    }
}

/**
 *  Servo hold
 *  - Head / Tooth parameters
 *  - Arms params (length and count)
 */
module servo_arm(params, arms) {

    head = params[0];
    tooth = params[1];

    head_diameter = head[0];
    head_heigth = head[1];
    head_thickness = head[2];
    head_screw_diameter = head[3];

    tooth_length = tooth[2];
    tooth_width = tooth[3];

    arm_length = arms[0];
    arm_count = arms[1];

    /**
     *  Servo arm
     *  - length is from center to last hole
     */
    module arm(tooth_length, tooth_width, head_height, head_heigth, hole_count = 1) {

        arm_screw_diameter = 2;

        difference() {
            union() {
                cylinder(r = tooth_width / 2, h = head_heigth);

                linear_extrude(height = head_heigth) {
                    polygon([
                        [-tooth_width / 2, 0], [-tooth_width / 3, tooth_length],
                        [tooth_width / 3, tooth_length], [tooth_width / 2, 0]
                    ]);
                }

                translate([0, tooth_length, 0]) {
                    cylinder(r = tooth_width / 3, h = head_heigth);
                }

                if (tooth_length >= 12) {
                    translate([-head_heigth / 2 + 2, 3.8, -4]) {
                        rotate([90, 0, 0]) {
                            rotate([0, -90, 0]) {
                                linear_extrude(height = head_heigth) {
                                    polygon([
                                        [-tooth_length / 1.7, 4], [0, 4], [0, - head_height + 5],
                                        [-2, - head_height + 5]
                                    ]);
                                }
                            }
                        }
                    }
                }
            }

            // Hole
            for (i = [0 : hole_count - 1]) {
                //translate([0, length - (length / hole_count * i), -1]) {
                translate([0, tooth_length - (4 * i), -1]) {
                    cylinder(r = arm_screw_diameter / 50, h = 10); //2 Loch 50 geschlossen
                }
            }

            cylinder(r = head_screw_diameter / 2, h = 10);
        }
    }

    difference() {
        translate([0, 0, 0.1]) {
            cylinder(r = head_diameter / 2 + head_thickness, h = head_heigth + 1);
        }

        cylinder(r = head_screw_diameter / 2, h = 10);

        servo_head(params);
    }

    arm_thickness = head_thickness;

    // Arm
    translate([0, 0, head_heigth]) {
        for (i = [0 : arm_count - 1]) {
            rotate([0, 0, i * (360 / arm_count)]) {
                arm(arm_length, head_diameter + arm_thickness * 2, head_heigth, 2);
            }
        }
    }
}

module demo() {
    rotate([0, 180, 0])
        servo_standard(arm_length, arm_count);
}

demo();

