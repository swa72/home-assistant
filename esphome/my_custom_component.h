#include "esphome.h"

class MyCustomComponent : public Component {
 public:
  void setup() override {
    // This will be called once to set up the component
    // think of it as the setup() call in Arduino
  pinMode(14, OUTPUT);                                                         //set enable pins as outputs
  pinMode(12, OUTPUT);
  pinMode(15, OUTPUT);
  pinMode(13, OUTPUT);
  }
  void loop() override {
    // This will be called very often after setup time.
    // think of it as the loop() call in Arduino
                digitalWrite(14, LOW);                                                       //set enable pins to enable the circuits
                digitalWrite(12, LOW);
                digitalWrite(15, HIGH);
                digitalWrite(13, LOW);

  }
};
