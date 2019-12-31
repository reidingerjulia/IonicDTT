import { Component, OnInit } from '@angular/core';
import {Elm} from '../../assets/js/main';
import { DTTService } from '../dtt.service';
import { Router } from '@angular/router';
declare var app: any;
@Component({
  selector: 'app-login',
  templateUrl: './login.page.html',
  styleUrls: ['./login.page.scss'],
})
export class LoginPage implements OnInit {
  username: String;
  constructor(public service: DTTService,public router: Router) {
   this.username="lucas";
   this.loginClick();
  }

   loginClick(){
    this.service.init(this.username);
    if(this.service.userHasLoggedIn == true)
      {
        this.router.navigateByUrl('/tabs/tab1');
      }
   }
  ngOnInit() {
  }
}
