import { Component } from '@angular/core';
import { Secret } from '../Models/secret';
import { DTTService } from '../dtt.service';
import { AlertController, ToastController } from '@ionic/angular';
import { LoadingController } from '@ionic/angular';
import * as jdenticon from 'jdenticon';
import { Observable } from 'rxjs';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';


@Component({
  selector: 'app-tab2',
  templateUrl: 'tab2.page.html',
  styleUrls: ['tab2.page.scss']
})
export class Tab2Page {
  secrets: Secret[] = [];
  svgs: String[];
  error: Error;
  constructor(public toastController: ToastController,private sanitizer: DomSanitizer, public loadingController: LoadingController, public service: DTTService, public alertController: AlertController) { 
  }
  ionViewWillEnter() {
    this.service.syncSecret();
  }
  /* loadSVGSecrets(){
    this.secrets.forEach(secret => {
      let d = document.getElementById(secret.hash.toString());
      d.innerHTML=this.getSvg(secret.hash).toString();
    });
  } */
  ngOnInit() { //Richtiger Code!!
    this.service.getData().subscribe(x => {
      if (x.error != null) {
        console.log(x.error.errorType);
        this.presentToast(x.error.errorType);
      } else if(x.secrets!=null){
        this.secrets = x.secrets;
        this.secrets.forEach(secret => {
          secret.img = this.sanitizer.bypassSecurityTrustHtml(jdenticon.toSvg(secret.hash, 200));
        });
        console.log(this.secrets);
      }
    });
  }
  /* getSvg(hash: String): String {
    return toSvg(hash, 100);
  } */
  async presentToast(error: String) {
    const toast = await this.toastController.create({
      message: error.toString(),
      duration: 2000
    });
    toast.present();
  }
  async presentAddPrompt() {
    const alert = await this.alertController.create({
      header: 'Add New Todo!',
      inputs: [
        {
          name: 'content',
          type: 'text',
          placeholder: 'Content'
        }
      ],
      buttons: [
        {
          text: 'Cancel',
          role: 'cancel',
          cssClass: 'secondary',
          handler: () => {
            console.log('Confirm Cancel');
          }
        }, {
          text: 'Ok',
          handler: (data) => {
            console.log('Confirm Ok');
            this.service.insertSecret(data.content);
          }
        }
      ]
    });

    await alert.present();
  }
  async presentRemovePrompt() {
    const alert = await this.alertController.create({
      header: 'Add New Todo!',
      inputs: [
        {
          name: 'content',
          type: 'text',
          placeholder: 'Content'
        }
      ],
      buttons: [
        {
          text: 'Cancel',
          role: 'cancel',
          cssClass: 'secondary',
          handler: () => {
            console.log('Confirm Cancel');
          }
        }, {
          text: 'Ok',
          handler: (data) => {
            console.log('Confirm Ok');
            this.service.deleteSecret(data.content);
          }
        }
      ]
    });

    await alert.present();
  }
  addNewSecret() {
    console.log("addNewSecret...");
    this.presentAddPrompt();
  }
  removeSecret(){
    console.log("removeSecret...");
    this.presentRemovePrompt();
  }
}
