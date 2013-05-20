String line;
boolean debug = false;
void setup()
{
  // start serial port at 115200 bps:
  Serial.begin(9600);
  Serial.write("SYS: boot complete!");
}

void loop()
{
   if(Serial.available() > 0)
   {
     char incomming = Serial.read();
     
     //Entering the & symbol toggles debug mode
     if(incomming == '&')
     {
       debug = !debug;
       return;
     }
     if(incomming == '*')
     {
        processLine();
        line = "";
     }
     //: signals the start of a new line
     if(incomming == ':')
     {
       line = ":";
     }
     else
     {
        line += incomming;
     }     
   }
}

//TODO: Reimplement this in bytes instead of ints
void processLine()
{
  if(line.length() == 0)
  {
     Serial.write("WRN: empty string detected, parsing halted!");
     return;
  }
  char temp[line.length() + 1];
  line.toCharArray(temp, line.length() + 1);
  
  //Serial.write(temp);
  //Serial.write("\n");
  
  //Verify string lenght
  if((line.length() - 1) % 2 != 0)
  {
     Serial.write("ERR: uneven number of hex characters detected!");
     return;
  }
  
  //Verify start character
  if(temp[0] != ':')
  {
      Serial.write("ERR: could not find start character of string!");
      return;
  }
  
  //Explode string into two-char chunks
  int arrayLen = (line.length() - 1) / 2;
  String stringBytes[arrayLen];
  byte intBytes[arrayLen];
  int bytesPos = 0;
  int currentPos = 1;
  while(currentPos < line.length())
  {
    if(bytesPos >= arrayLen)
    {
      Serial.write("ERR: bytesPos exceeded bytes length!");
      return; 
    }
    stringBytes[bytesPos] += "0x";
    
    for(int i = 0; i < 2; i++)
    {
      stringBytes[bytesPos] += line.charAt(currentPos++);
    }
    char hexCode[stringBytes[bytesPos].length() + 1];
    stringBytes[bytesPos].toCharArray(hexCode, stringBytes[bytesPos].length() + 1);
    intBytes[bytesPos] = strtoul(hexCode, NULL, 16);
    
    if(debug)
    {
      Serial.write("Hex chars: ");
      Serial.write(hexCode);
      Serial.write("   Int Val: ");
      Serial.print(intBytes[bytesPos], DEC);
      Serial.write("\n");
    }
    
    bytesPos++;
  }
  
  //At this point, intBytes should look like this:
  // ByteCount Address RecordType     Data      CheckSum
  // [  int  ],[  ,  ],[        ],[ByteCount*,],[      ]
  
  //Verify checksum
  //The last byte is the two's compliment of the total
  int total = 0;
  for(int i = 0; i < (arrayLen - 1); i++)
  {
    if(debug)
    {
      Serial.write("Adding byte ");
      Serial.print(i, DEC);
      Serial.write(" : ");
      Serial.print(intBytes[i], DEC);
      Serial.write("\n");
    }
    total += intBytes[i];
  }
  if(debug)
  {
    Serial.write("Total :");
    Serial.print(total, DEC);
    Serial.write("\n");
    Serial.write("Total AND 0xFF :");
    Serial.print(total & 0xFF, DEC);
    Serial.write("\n");
  }
    
  //Need only 1 byte from this int to twos compliment
  if(twosCompliment(total & 0xFF) != intBytes[arrayLen - 1])
  {
     Serial.write("ERR: checksum verification failed!");
     return; 
  }
  else
  {
    Serial.write("MSG: checksum verified!");
  }
  //Generate int array
}

int twosCompliment(byte input)
{
  if(debug)
  {
    Serial.write("Twos Compliment Input :");
    Serial.print(input, BIN);
    Serial.write("\n");
  }
  
  unsigned int temp = ~input;
  byte twosCompliment = temp & 0xFF;
  
  if(debug)
  {
    Serial.write("Twos Compliment Stage 1 :");
    Serial.print(twosCompliment, BIN);
    Serial.write(" = ");
    Serial.print(twosCompliment, DEC);
    Serial.write("\n"); 
  }
  
  twosCompliment++;
  
  if(debug)
  {
    Serial.write("Twos Compliment Stage 2 :");
    Serial.print(twosCompliment, BIN);
    Serial.write(" = ");
    Serial.print(twosCompliment, DEC);
    Serial.write("\n");
  }
  return twosCompliment;
}

