package com.reactirislibrary;

import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.support.annotation.Nullable;
import android.support.v4.content.LocalBroadcastManager;
import android.util.AttributeSet;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.widget.AbsoluteLayout;
import android.widget.RelativeLayout;

import com.comcast.irisrtcsdk.IrisRtcSdk.IrisRtcMediaTrack;
import com.comcast.irisrtcsdk.IrisRtcSdk.IrisRtcRenderer;

import org.webrtc.RendererCommon;
import org.webrtc.SurfaceViewRenderer;

/**
 * Created by Manish Ganvir on 1/19/18.
 */

public class RNIrisVideoView extends SurfaceViewRenderer implements IrisRtcRenderer.IrisRtcRendererObserver, RendererCommon.RendererEvents {
    private static final String TAG = "React--IrisRtcSdk";
    private IrisRtcRenderer mRenderer;
    private String mStreamId;
    private int mwidthSpec;
    private int mheightSpec;
    private int mleft, mtop, mright, mbottom;

    /**
     * Constructor
     *
     * @param context - Android context
     * @param attrs   - Attributes (Ignored by this class)
     */
    public RNIrisVideoView(Context context, AttributeSet attrs) {
        super(context, attrs);
        InitView(context);

    }

    /**
     * Constructor
     *
     * @param context - Android context
     */
    public RNIrisVideoView(Context context) {
        super(context);
        InitView(context);
    }

    /**
     * To initialize the view
     *
     * @param context Android (passed by react) context
     */
    public void InitView(Context context) {
        Log.i(TAG, " RNIrisVideoView: initview ");
        mStreamId = null;
        mwidthSpec =0; mheightSpec =0;
        this.init(RNIrisSdkModule.getEglBase().getEglBaseContext(), this);
        this.bringToFront();

        // We are registering an observer (mMessageReceiver) to receive Intents
        LocalBroadcastManager.getInstance(context).registerReceiver(
                mMessageReceiver, new IntentFilter("onAllTracksDeleted"));
        LocalBroadcastManager.getInstance(context).registerReceiver(
                mMessageReceiver, new IntentFilter("onTrackDeleted"));
    }

    // Our handler for received Intents. This will be called whenever an Intent
    private BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Log.i(TAG, " RNIrisVideoView: BroadcastReceiver -- onReceive " + intent.toString());

            // Check the intent action
            if ( (intent.getAction() == "onTrackDeleted" && intent.getStringExtra("TrackId") == mStreamId) ||
                    intent.getAction() == "onAllTracksDeleted")
            {
                if (mStreamId != null) {
                    final IrisRtcMediaTrack track = RNIrisSdkStreamManager.getInstance().getTrack(mStreamId);
                    track.removeRenderer(mRenderer);
                    mRenderer.disposeRenderer();
                    mRenderer = null;
                    RNIrisSdkStreamManager.getInstance().removeTrack(mStreamId);
                    mStreamId = null;
                }
            }
        }
    };
    /**
     * To set the stream id associated with the view
     *
     * @param StreamId - Stream Id as returned as by the callbacks
     */
    public void SetStreamId(@Nullable String StreamId) {
        Log.i(TAG, " RNIrisVideoView: SetStreamId with " + StreamId);

        // Delete the old renderer, if it exists
        if (mStreamId != null)
        {
            final IrisRtcMediaTrack track = RNIrisSdkStreamManager.getInstance().getTrack(mStreamId);
            track.removeRenderer(mRenderer);
            //mRenderer.disposeRenderer();
            //mRenderer = null;
        }
        mStreamId = StreamId;
        maybeAddRenderer();


    }

    private void maybeAddRenderer() {
        // From the streamid, find out the corresponding track
        final IrisRtcMediaTrack track = RNIrisSdkStreamManager.getInstance().getTrack(mStreamId);

        // Check if found something
        if (track != null) {
            final Handler mHandler = new Handler();
            mRenderer = new IrisRtcRenderer(mleft, mtop, mright, mbottom, IrisRtcRenderer.IrisSdkScaleType.SCALE_ASPECT_FIT, false, this);

            mHandler.post(new Runnable() {

                @Override
                public void run() {


                    // Add renderer to the track
                    track.addRenderer(mRenderer);

                    mHandler.postDelayed(new Runnable() {

                        @Override
                        public void run() {

                            // Add renderer to the track
                            if (mheightSpec != 0)
                                RNIrisVideoView.super.measure(mwidthSpec, mheightSpec);
                        }
                    }, 100);

                }
            });

        }
    }

    /**
     * Callback: This method is called when there is change in size coordinates of remote or local video.
     */
    @Override
    public void onVideoSizeChange() {
        Log.i(TAG, " RNIrisVideoView: onVideoSizeChange called ");

    }

    @Override
    public void onFirstFrameRendered() {
        Log.i(TAG, " RNIrisVideoView: onFirstFrameRendered ");
    }

    @Override
    public void onFrameResolutionChanged(int i, int i1, int i2) {
        Log.i(TAG, " RNIrisVideoView: onFrameResolutionChanged ");
        final Handler mHandler = new Handler();

        mHandler.post(new Runnable() {

            @Override
            public void run() {

                // Add renderer to the track
                RNIrisVideoView.super.measure(mwidthSpec, mheightSpec);
            }
        });
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        Log.i(TAG, " RNIrisVideoView: surfaceChanged " + width + ":" + height);

        super.surfaceChanged(holder, format, width, height);
    }

    @Override
    protected void onMeasure(int widthSpec, int heightSpec) {
        Log.i(TAG, " RNIrisVideoView: onMeasure " + widthSpec + ":" + heightSpec);

        mwidthSpec = widthSpec;
        mheightSpec = heightSpec;
        super.onMeasure(widthSpec, heightSpec);
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        Log.i(TAG, " RNIrisVideoView: onLayout " + changed + "-" + left + ":" + top + ":" + right + ":" + bottom);

        if (changed) {
            mleft = left;
            mtop = top;
            mright = right;
            mbottom = bottom;
           // mRenderer.updateRenderer(left, top, right, bottom, IrisRtcRenderer.IrisSdkScaleType.SCALE_ASPECT_FIT, false, this.g);
        }
        super.onLayout(changed, left, top, right, bottom);
    }
}
