import 'dart:developer';
import 'dart:io';

import 'package:admin/app/constant/collection_name.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/constant/show_toast.dart';
import 'package:admin/app/models/banner_model.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class BannerScreenController extends GetxController {
  RxString title = "Banner".tr.obs;

  Rx<TextEditingController> bannerName = TextEditingController().obs;
  Rx<TextEditingController> bannerDescription = TextEditingController().obs;
  Rx<TextEditingController> bannerImageName = TextEditingController().obs;
  Rx<File> imageFile = File('').obs;
  RxString mimeType = 'image/png'.obs;
  RxBool isLoading = false.obs;
  RxList<BannerModel> bannerList = <BannerModel>[].obs;
  Rx<BannerModel> bannerModel = BannerModel().obs;

  RxBool isEditing = false.obs;
  RxBool isImageUpdated = false.obs;
  RxString imageURL = "".obs;
  RxString editingId = "".obs;

  Rx<TextEditingController> offerText = TextEditingController().obs;
  RxBool isOfferBanner = false.obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    isLoading(true);
    bannerList.clear();
    List<BannerModel> data = await FireStoreUtils.getBanner();
    bannerList.addAll(data);
    isLoading(false);
  }

  setDefaultData() {
    bannerName.value.text = "";
    bannerDescription.value.text = "";
    bannerImageName.value.text = "";
    isEditing.value = false;
    bannerName.value.clear();
    bannerDescription.value.clear();
    bannerImageName.value.clear();
    imageFile.value = File('');
    mimeType.value = 'image/png';
    editingId.value = '';
    isEditing.value = false;
    isImageUpdated.value = false;
    imageURL.value = '';
    offerText.value.text = '';
    isOfferBanner.value = false;
  }

  Future<void> updateBanner(BuildContext context) async {
    Navigator.pop(context);
    isEditing.value = true; // Use .value for Obx variables
    String docId = bannerModel.value.id!;

    try {
      // Check if the image file path is not empty
      if (imageFile.value.path.isNotEmpty) {
        // Use XFile instead of PickedFile
        XFile imageFileX = XFile(imageFile.value.path);

        // Upload image and get the URL
        String? url = await FireStoreUtils.uploadPic(
          imageFileX, // Pass XFile instead of PickedFile
          "bannerImage",
          docId,
          mimeType.value,
        );

        log('Image URL in update: $url');
        bannerModel.value.image = url;
      }

      // Update banner model properties
      bannerModel.value.bannerName = bannerName.value.text;
      bannerModel.value.bannerDescription = bannerDescription.value.text;
      bannerModel.value.isOfferBanner = isOfferBanner.value;
      bannerModel.value.offerText = offerText.value.text;

      // Update banner data in Firestore
      await FireStoreUtils.updateBanner(bannerModel.value);
      setDefaultData();
      await getData();
    } catch (e) {
      // Handle errors
      print("Error updating banner: $e");
      ShowToastDialog.toast(
          "An error occurred while updating the banner. Please try again.".tr);
    } finally {
      // Ensure editing state is updated
      isEditing.value = false; // Use .value for Obx variables
    }
  }

  Future<void> addBanner(BuildContext context) async {
    Navigator.pop(context);

    if (imageFile.value.path.isNotEmpty) {
      isLoading.value = true; // Use .value for Obx variables
      String docId = Constant.getRandomString(20);

      try {
        // Use XFile instead of PickedFile
        XFile imageFileX = XFile(imageFile.value.path);

        // Upload image and get the URL
        String? url = await FireStoreUtils.uploadPic(
          imageFileX, // Pass XFile instead of PickedFile
          "bannerImage",
          docId,
          mimeType.value,
        );

        log('Image URL in addBanner: $url');
        bannerModel.value.id = docId;
        bannerModel.value.image = url;
        bannerModel.value.bannerName = bannerName.value.text;
        bannerModel.value.bannerDescription = bannerDescription.value.text;
        bannerModel.value.isOfferBanner = isOfferBanner.value;
        bannerModel.value.offerText = offerText.value.text;

        // Add banner data to Firestore
        await FireStoreUtils.addBanner(bannerModel.value);
        setDefaultData();
        await getData();
      } catch (e) {
        // Handle errors
        print("Error adding banner: $e");
        ShowToastDialog.toast(
            "An error occurred while adding the banner. Please try again.".tr);
      } finally {
        // Ensure loading state is updated
        isLoading.value = false; // Use .value for Obx variables
      }
    } else {
      ShowToastDialog.toast("Please select a valid banner image".tr);
    }
  }

  removeBanner(BannerModel bannerModel) async {
    isLoading = true.obs;
    await FirebaseFirestore.instance
        .collection(CollectionName.banner)
        .doc(bannerModel.id)
        .delete()
        .then((value) {
      ShowToastDialog.toast("Banner deleted...!".tr);
    }).catchError((error) {
      ShowToastDialog.toast("Something went wrong".tr);
    });
    isLoading = false.obs;
    getData();
  }
}
