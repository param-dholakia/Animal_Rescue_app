/*
 * Copyright 2024 Canardoux.
 *
 * This file is part of the Flutter Sound project.
 *
 * Flutter Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2), as published by
 * the Mozilla organization..
 *
 * Flutter Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the Mozilla Public License
 * along with Flutter Sound.  If not, see <https://www.gnu.org/licenses/>.
 */


// The number of ouputs is either 0 or one. We do not handdle the case where number of outputs > 1

class FlutterSoundStreamProcessor extends AudioWorkletProcessor {

  constructor(...args) {
    super(...args);
    this.port.onmessage = (e) => {
      //console.log('Rcv ' + e.data);
      //this.port.postMessage("pong (" + e.data + ")");
      //let msg = e.data;
      //let msgType = msg['msgType'];
      //let outputNo = msg['outputNo'];
      //let data = msg['data'];
      //switch (msgType)
      //{
        //case 'SEND_DATA': this.send(outputNo, data); break;
        //case 'STOP': this.stop(); break;
      //}
            let msg = e.data;
    };
  }



  receive(inNo, data)
  {
    this.port.postMessage({ 'messageType' : 'RECEIVE_DATA', 'inputNo' : inNo,  'data': data});
  }


  send(outNo, data)
  {
    for (let channel = 0; channel < data.length; ++ channel)
    {
        for (let i = 0; i < data.length; ++i)
        {
            let x = Math.random() * 2 -1;
            data[channel][i] = x;
        }
    }
  }


  process(inputs, outputs, parameters) {

      let inNo = 0;
      inputs.forEach((input) => // For each input (Probably just one input)
      {
            this.receive(inNo, input);
            ++ inNo;
      });
      
      let outNo = 0;
      outputs.forEach((output) => // For each output (Probably just one or zero output)
      {
            this.send(outNo, output);
            ++ outNo;
      });


    return true;
  }



}

registerProcessor("flutter-sound-stream-processor", FlutterSoundStreamProcessor);