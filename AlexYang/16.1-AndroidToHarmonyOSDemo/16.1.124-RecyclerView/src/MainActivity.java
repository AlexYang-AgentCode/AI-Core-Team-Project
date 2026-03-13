package com.example.recyclerviewdemo;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import java.util.Arrays;
import java.util.List;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        List<String> items = Arrays.asList(
            "Apple", "Banana", "Cherry", "Date", "Elderberry",
            "Fig", "Grape", "Honeydew", "Kiwi", "Lemon");

        RecyclerView rv = findViewById(R.id.recyclerView);
        rv.setLayoutManager(new LinearLayoutManager(this));
        rv.setAdapter(new RecyclerView.Adapter<RecyclerView.ViewHolder>() {
            @Override
            public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
                TextView tv = new TextView(parent.getContext());
                tv.setPadding(32, 24, 32, 24);
                tv.setTextSize(18);
                return new RecyclerView.ViewHolder(tv) {};
            }
            @Override
            public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
                ((TextView) holder.itemView).setText(items.get(position));
            }
            @Override
            public int getItemCount() { return items.size(); }
        });
    }
}
