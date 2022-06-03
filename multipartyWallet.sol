//SPDX-License-Identifier: UNLICENSED

// owner = token owners
// admin = Administrator he controls the whole system

/** what is not , 
need to check-->
still admin can remove the owner after he submitted the proposal
**/

/** 
Variables =>
addMoney = anybody can add money to the contract
addOwner = only admin can add members format "wallet address,string" eg : 0x00000000000..,"Jothish"
exicuteProp= for exicuting proposal only works by proposal submited member,this will add requested money to sender address,it will works only certain percentage of members vote avilable percentage default is 60(approvalPercentage) or admin can change the value 
ownerApproveStat=cast vote by members if the proposal is submitted,it will change approved status to true
removeOwner=only works with admin a/c , for removing alredy added owner aacount format "wallet address", eg : 0x0000000..
submitPropos= submit proposal only a member can submit a proposal,it only works if the wallet amount is greater that requsted amount format "uint", eg: 12 ,need to enter amount in ether, 
updatePercent = change needed vote percentage for proposal exicution , only works with admin ,format "uint", eg : 55 ,user any number between 1-100
withdrawPropos = For withdraw proposal that made by a member, sombody will change mind , only works with proposal submitted owner
viewBalance = view avilable wallet balance
viewOwnersList=view the keyList array 


How this works..... =>

deploy the contract
add ether to the contract from admin account
add owner accounts along with names from admin account
any owner can submit a proposal to withdraw money from contract
other owners need to approve the proposal
if required percentage of other owners approved then proposal submitted member can exicute proposal and take money



**/

pragma solidity ^0.8.7;

contract multipartyWallet{

    address admin;
    address[] keyList;
    uint approvalPercentage=60;
    bool transactionProp = false;
    uint transactionPropAmount;
    address transactionPropMember;
    uint walletBalance=0;// in eather


    constructor() {
        admin=msg.sender;    //declaring contract deployer as message Admin
    }
    
    modifier adminOnly{  //modifier named as only Admin
        require(msg.sender == admin,"you must be admin to add owners");
        _;
    }

    modifier membersOnly{
        bool isIn=false; //default false 
        if (keyList.length >0){  //for checking that addres is in the keyList array
            for (uint8 i;i<keyList.length;i++){
                if (keyList[i]==msg.sender){
                    isIn=true;
                }
            }
        }
        require(isIn,"You are not added by Admin contact him"); //address is in the keyList then only the next code will exicute
        _;
    }


    struct owners { //owners struct
        address ownerAddr; //owner address
        string name; //owners name
        bool approval; // owner approved the transaction or not 
    }

    mapping (address => owners) ownersMap; // for mapping owners

    function addMoney() public payable { //add money to contract allowed anyone to add money :D
        walletBalance=address(this).balance/1000000000000000000; //for converting wei to ether
    }

    function viewBalance() public view returns(uint _balance,uint _etherBalance){ // to view balance in this contract
        return (_balance=address(this).balance,_etherBalance=walletBalance);
    }




    function addOwner(address _ownerAddr,string memory _name) public adminOnly { // adding token owners 

        bool isIn=true; //default false 
        if (keyList.length >0){  //for checking that address is in the keyList array coz if he alredy in the list that will duplicate
            for (uint8 i;i<keyList.length;i++){
                if (keyList[i]==_ownerAddr){
                    isIn=false;
                }
            }
        }
        require(isIn,"owner alredy added"); //address is in the keyList then only the next code will exicute

        ownersMap[msg.sender]=owners(_ownerAddr, _name,false); // adding token owner wallet address , name and approval(default ad false)   
        keyList.push(_ownerAddr); // adding aded owner address to a array for counting purpose  
    }

    function removeOwner(address _ownerAddr) public adminOnly{
        delete ownersMap[_ownerAddr]; // removing token owner from mapping
        for (uint i;i<keyList.length;i++){ // removing token owner address from array
            if (keyList[i]==_ownerAddr){
                delete keyList[i]; // removing the owner address
                keyList[i]=keyList[keyList.length -1]; // if we remove a element from the array a null element will created insted of the original 1 for removing that change the last element position to removed 1 position then last use pop function to remove the last element to clean the array
            }
        }
        keyList.pop(); // to remove the last duplicated element
    }

    function updatePercent(uint8 _approvalPercentage) public adminOnly{ //update approval pencentage
        approvalPercentage=_approvalPercentage;
    }

    function viewOwnersList() public view returns(uint _length,address[] memory _keyList){ // getting no of token owners 
        _length=keyList.length;
        _keyList=keyList;
    }


    function ownerApproveStat() public membersOnly { // change approval status 
        
        ownersMap[msg.sender].approval=true; // change the approval stat
    }

    function submitPropos(uint _transactionPropAmount) public membersOnly { // submit proposel by a member
        if (transactionProp == false) { // check transaction proposed or not
            require(_transactionPropAmount <= walletBalance,"wallet balance not enough");
            transactionPropAmount=_transactionPropAmount; // updating proposed transaction amount
            transactionPropMember=msg.sender; //transaction proposed member
            transactionProp=true; //transaction proposed to true
            ownersMap[transactionPropMember].approval=true; //transaction submitted member approval changed to true from false(dafault)
        
        }
    }

    function withdrawPropos() public membersOnly{ // for widraw proposel
        if (transactionProp) { // check transaction proposed or not
            require(transactionPropMember==msg.sender); //require transaction only withdraw by proposed memeber 
            transactionProp=false; // change propose status to false
            transactionPropAmount=0; // revert request amount to 0  
            for(uint i;i<keyList.length;i++){ // for removing all other member approval to false 
                ownersMap[keyList[i]].approval=false;
            }
        }
        
    }

    function avgPer() internal view returns(uint _averagePercen){
        uint totalApproved=0;
        uint totalRefused=0;
        for(uint i;i<keyList.length;i++){
            if (ownersMap[keyList[i]].approval){
                totalApproved++;
            }
            else{
                totalRefused++;
            }
        }
        uint val=totalApproved*100; // cant use totalApproved/totalno *100 coz uint not support franctional no that will auto matically goto zero  
        uint avg=val/(totalRefused+totalApproved);// so we first multiply with 100 the  divide with total

    return (_averagePercen=avg);

    }


    function exicuteProp() public payable membersOnly {
      
        uint averagePercen=avgPer();
        
        require(transactionProp,"Transanction not proposed,propose the transaction first"); // check transaction proposed or not
        require(averagePercen>=approvalPercentage,"you did't get the needed votes");
        require(transactionPropMember==msg.sender,"you are not the person who submit the proposel"); //require transaction only withdraw by proposed memeber 
        payable(transactionPropMember).transfer(transactionPropAmount*1000000000000000000); // transfering request amount to proposal owner converting to ether to wei

        // returning back all variables to default
        transactionProp=false; // change propose status to false
        transactionPropAmount=0; // revert request amount to 0  
        for(uint i;i<keyList.length;i++){ // for removing all other member approval to false 
            ownersMap[keyList[i]].approval=false;
            }



}



    




}
