package com.reactirislibrary;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import android.os.Build;
import android.support.annotation.Nullable;
import android.util.Log;

/**
 * Created by Manish Ganvir on 1/19/18.
 */

public class RNIrisVideoViewManager extends SimpleViewManager<RNIrisVideoView> {
    private static final String TAG = "React--IrisRtcSdk";
    public static final String REACT_CLASS = "IrisVideoView";

    private ThemedReactContext mContext = null;

    public RNIrisVideoViewManager() {
    }

    /**
     * Get the react class name
     * @return react class name
     */
    @Override
    public String getName() {
        return REACT_CLASS;
    }

    /**
     * To Create view instance
     * @param reactContext react context
     * @return custom view which ties with webrtc
     */
    @Override
    protected RNIrisVideoView createViewInstance(ThemedReactContext reactContext) {
        mContext = reactContext;

        return new RNIrisVideoView(reactContext);
    }

    /**
     * To set the stream id associated with the view
     * @param view - The view (video)
     * @param StreamId - Stream Id as returned as by the callbacks
     */
    @ReactProp(name = "StreamId")
    public void SetStreamId(RNIrisVideoView view,  @Nullable String StreamId){
        view.SetStreamId(StreamId);
    }

    /**
     * Set the z order
     * @param z - Float z order value
     */
    /*@ReactProp(name = "zIndex")
    public void setZIndex(RNIrisVideoView view, float z){
        Log.i(TAG, " RNIrisVideoViewManager: setZIndex " + z);

        // Make sure we're running on Honeycomb or higher to use ActionBar APIs
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            view.getParent(). setZ(z);
        }
    }*/
}
