// Criar um sketch. Esse código testa MQTT com Python sem segurança.
const int led = 8;
int estadoler = 10;

void setup() {
  Serial.begin(9600);
  pinMode(led, OUTPUT); 
  while (!Serial) {
    ;
  }
}

String leStringSerial() {
  String conteudo = "";
  char caractere;
  while (Serial.available() > 0) { 
    caractere = Serial.read(); 
    if (caractere != '\n') { 
      conteudo.concat(caractere); 
    }
    delay(10); 
  }
  Serial.print("Recebi: ");
  Serial.println(conteudo);
  return conteudo;
}

void loop() {
  while (Serial.available() > 0) { 
    int est = digitalRead(led);
    String recebido = leStringSerial(); 
    if (recebido == "L1") { 
      if (est == 0) {
        digitalWrite(led, HIGH); 
      } else if (est == 1) {
        digitalWrite(led, LOW); 
      }
    }
    delay(1); 
  }
}
