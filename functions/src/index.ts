import * as functions from "firebase-functions";
import * as admin from "firebase-admin";


admin.initializeApp();

export const getFollower = functions.firestore.document("Follower/{userId}")
    .onUpdate(async (data, context) => {
      const userId = context.params.userId;
      const newData = data.after.data();
      const oldData = data.before.data();

      if (newData.followerVal > oldData.followerVal) {
        const querySnaphsot = await admin.firestore().collection("User")
            .doc(userId).collection("Token").get();

        const newList : [] = newData.follower;
        const oldList : [] = oldData.follower;
        const followerId = newList.filter((item) => oldList.indexOf(item) < 0);

        const followerSnapshot = await admin.firestore().collection("User")
            .doc(followerId[0]).get();

        if (!querySnaphsot.empty) {
          const tokens = querySnaphsot.docs.map((snap) => snap.id);
          const followerData = followerSnapshot.data();
          const payload = {
            notification: {
              title: "Du hast einen neuen Follower",
              body: followerData!["username"] + "folgt dir jetzt",
            },
          };
          admin.messaging().sendToDevice(tokens, payload,
              {contentAvailable: true, priority: "high"});

          const addEntry = admin.firestore().collection("User").doc(userId)
              .collection("News").doc();
          addEntry.set({name: followerData!["name"],
            userName: followerData!["username"],
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            msg: " folgt dir jetzt"});
          admin.firestore().collection("User").doc(userId)
              .collection("News").doc("unreadNews")
              .update({count: admin.firestore.FieldValue.increment(1)});

          return;
        }

        functions.logger.log("QuerySnapshot empty");
      }

      functions.logger.log("Entfolgt");
      return null;
    });


export const onPostUpdate = functions.firestore.document("Posts/{postId}")
    .onUpdate(async (data, context) => {
      const postId = context.params.postId;
      const oldData = data.before.data();
      const newData = data.after.data();

      const userName : string = oldData.authorUserName;
      functions.logger.log(userName);

      const oldComments : [] = oldData.comments;
      const newComments : [] = newData.comments;

      const oldLikes : [] = oldData.likedBy;
      const newLikes : [] = newData.likedBy;

      const snapshot = await admin.firestore().collection("UserNames")
          .doc(userName.toLowerCase()).get();

      const userId = snapshot.data()!["uid"];

      const querySnaphsot = await admin.firestore().collection("User")
          .doc(userId).collection("Token").get();

      const tokens = querySnaphsot.docs.map((snap) => snap.id);

      if (newComments.length > oldComments.length) {
        const commId = newComments
            .filter((item) => oldComments.indexOf(item) < 0);
        const commSnapshot = await admin.firestore().collection("Posts")
            .doc(commId[0]).get();
        const commUserData = commSnapshot.data();
        functions.logger.log(commUserData);
        const payload = {
          notification: {
            title: "Dein Beitrag wurde kommentiert",
            body: commUserData!["authorUserName"] +
              " hat deinen Beitrag kommentiert",
          },
        };

        admin.messaging().sendToDevice(tokens, payload,
            {contentAvailable: true, priority: "high"});

        const addEntry = admin.firestore().collection("User").doc(userId)
            .collection("News").doc();
        addEntry.set({name: commUserData!["authorName"],
          userName: commUserData!["authorUserName"],
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          msg: " hat deinen Beitrag kommentiert",
          post: postId});

        admin.firestore().collection("User").doc(userId)
            .collection("News").doc("unreadNews")
            .update({count: admin.firestore.FieldValue.increment(1)});
      } else if (newLikes.length > oldLikes.length) {
        const likeUserId = newLikes
            .filter((item) => oldLikes.indexOf(item) < 0);
        const likeUserSnapshot = await admin.firestore().collection("User")
            .doc(likeUserId[0]).get();
        const likeUserData = likeUserSnapshot.data();

        const payload = {
          notification: {
            title: "Dein Beitrag wurde geliket",
            body: likeUserData!["username"] + " gefällt dein Beitrag",
          },
        };
        admin.messaging().sendToDevice(tokens, payload,
            {contentAvailable: true, priority: "high"});

        const addEntry = admin.firestore().collection("User").doc(userId)
            .collection("News").doc();
        addEntry.set({name: likeUserData!["name"],
          userName: likeUserData!["username"],
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          msg: " gefällt dein Beitrag",
          post: postId});

        admin.firestore().collection("User").doc(userId)
            .collection("News").doc("unreadNews")
            .update({count: admin.firestore.FieldValue.increment(1)});
      }
    });
