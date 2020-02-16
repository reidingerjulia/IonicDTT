import { Component } from '@angular/core';
import { DTTService } from '../dtt.service';
import { AlertController, ToastController, IonItem } from '@ionic/angular';
import { LoadingController } from '@ionic/angular';
import { Budget } from '../Models/budget';
import { Spending } from '../Models/spending';

@Component({
  selector: 'app-tab3',
  templateUrl: 'tab3.page.html',
  styleUrls: ['tab3.page.scss']
})
export class Tab3Page {
  budget: Budget;
  spendings: Spending[];
  displaySpendings: Spending[];
  totalAmount: Number;
  username: String = "";
  minus: Number = 0.0;
  plus: Number = 0.0;
  displayBalance: number;

  constructor(public toastController: ToastController, public loadingController: LoadingController, public service: DTTService, public alertController: AlertController) { }


  ionViewWillEnter() {
    this.service.syncBudget();
  }
  ngOnInit() { //Richtiger Code!!
    this.service.getData().subscribe(x => {
      if (x.error != null) {
        console.log(x.error.errorType);
        this.presentToast(x.error.errorType);
      } else if (x.budget != null) {
        this.displaySpendings = new Array();
        this.budget = x.budget;
        this.spendings = this.budget.spendings;
        this.totalAmount = this.budget.totalCent;
        this.displayBalance = this.budget.totalCent as number / 100;
        if (this.totalAmount < 0) {
          this.plus = 0.0;
          this.minus = Math.abs(this.totalAmount as number) / 10000;
        }else{
          this.minus = 0.0;
          this.plus = Math.abs(this.totalAmount as number) / 10000;
        }
        console.log(this.budget);
        this.spendings.forEach(spending => {
          let d = new Date(spending.lastUpdated as number);
          spending.dateTime = d.toLocaleDateString();
          this.displaySpendings.push(spending);
          console.log(this.displaySpendings);
        });

        this.username = this.service.username;
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
  addNewSpending() {
    console.log("addNewSpending...");
    this.presentAddPrompt();
  }
  delete(item) {
    console.log("delete...");
    this.service.deleteBudget(item.id);
  }
  update(item) {
    console.log("update...");
    this.presentEditPrompt(item);
  }
  async presentAddPrompt() {
    const alert = await this.alertController.create({
      header: 'Add New Spending!',
      inputs: [
        {
          name: 'content',
          placeholder: 'Content'
        },
        {
          name: 'amount',
          placeholder: 'Cent Amount',
          type: 'number'
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
            this.service.insertBudget(data.content, parseInt(data.amount));
          }
        }
      ]
    });

    await alert.present();
  }
  async presentEditPrompt(item: Spending) {
    const alert = await this.alertController.create({
      header: 'Edit Spending!',
      inputs: [
        {
          name: 'content',
          type: 'text',
          placeholder: '' + item.reference,
          value: item.reference
        },
        {
          name: 'amount',
          placeholder: ''+item.cent,
          type: 'number',
          value: item.cent
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
            this.service.updateBudget(item.id,parseInt(data.amount),data.content);
          }
        }
      ]
    });

    await alert.present();
  }

}
