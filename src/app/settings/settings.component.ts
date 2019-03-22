import { Component, OnInit } from '@angular/core';
import { AngularFireDatabase, AngularFireObject } from '@angular/fire/database';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.css']
})
export class SettingsComponent implements OnInit {
  settingsRef: AngularFireObject<any>;
  settings: any;

  constructor(private db: AngularFireDatabase) { }

  ngOnInit() {
    this.settingsRef = this.db.object('settings');
    this.settingsRef.snapshotChanges().subscribe(settings => {
      this.settings = settings.payload.val();
    });
  }

  save() {
    this.settingsRef.update(this.settings);
  }
}
