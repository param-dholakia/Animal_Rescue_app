#User function Template for python3
class Solution:
    def getSecondLargest(self, arr):
        a=list(arr)
        a.sort(reverse=True)
        i=len(a)
        x=0
        while(a[x]==a[x+1]):
            if(x+1<i-1):
                x=x+1
            elif(a[x]==a[i-1]):
                return -1
            else:
                return a[-1]
        return a[x+1]
#{ 
 # Driver Code Starts
# Initial Template for Python 3

if __name__ == "__main__":
    t = int(input())
    for _ in range(t):
        arr = list(map(int, input().split()))
        ob = Solution()
        ans = ob.getSecondLargest(arr)
        print(ans)
        print("~")
# } Driver Code Ends