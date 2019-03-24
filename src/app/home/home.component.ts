import { Component, OnInit } from '@angular/core';
import { AngularFireDatabase, AngularFireObject } from '@angular/fire/database';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {
  items: Observable<any[]>;
  settingsRef: AngularFireObject<any>;
  settings: any;

  constructor(private db: AngularFireDatabase) { }

  ngOnInit(): void {
    this.settingsRef = this.db.object('settings');
    this.settingsRef.snapshotChanges().subscribe(action => {
      this.settings = action.payload.val();

      this.items = this.db.list('data').valueChanges().pipe(map(x => {
        x.forEach((e) => {
          const c = e as any;
          c.name = this.settings.transmitter[c.transmitter_id].name;
          const localDateTimeString = (new Date(c.time + ' GMT+00:00')).toString();
          const lastColonIndex = localDateTimeString.lastIndexOf(':');
          c.timeToDisplay = localDateTimeString.substring(0, lastColonIndex);
          c.sensors.forEach(s => s.name = this.settings.transmitter[c.transmitter_id].sensors[s.sensor - 1]);
        });
        return x;
      }));
    });
  }
}
